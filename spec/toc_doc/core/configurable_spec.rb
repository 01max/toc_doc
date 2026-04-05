# frozen_string_literal: true

RSpec.describe TocDoc::Configurable do
  it 'lists valid configuration keys' do
    expect(described_class.keys).to include(*%i[api_endpoint user_agent middleware connection_options
                                                default_media_type per_page connect_timeout read_timeout
                                                pagination_depth rate_limit cache])
  end

  it 'resets to default options' do
    instance = Class.new { extend TocDoc::Configurable }
    instance.api_endpoint = 'https://override.example'

    expect { instance.reset! }.to change { instance.api_endpoint }.to(TocDoc::Default.api_endpoint)
  end

  it 'resets connect_timeout to the default value' do
    instance = Class.new { extend TocDoc::Configurable }
    instance.connect_timeout = 999

    expect { instance.reset! }.to change { instance.connect_timeout }.to(TocDoc::Default::CONNECT_TIMEOUT)
  end

  it 'resets read_timeout to the default value' do
    instance = Class.new { extend TocDoc::Configurable }
    instance.read_timeout = 999

    expect { instance.reset! }.to change { instance.read_timeout }.to(TocDoc::Default::READ_TIMEOUT)
  end

  it 'calls Default.reset! when reset! is invoked' do
    instance = Class.new { extend TocDoc::Configurable }

    expect(TocDoc::Default).to receive(:reset!).at_least(:once)

    instance.reset!
  end

  it 'returns options as a hash' do
    instance = Class.new { extend TocDoc::Configurable }
    instance.api_endpoint = 'https://example.test'

    expect(instance.options[:api_endpoint]).to eq('https://example.test')
    expect(instance.options.keys).to match_array(TocDoc::Configurable.keys)
  end

  it 'detects when options hashes are the same' do
    instance = Class.new { extend TocDoc::Configurable }
    opts = instance.options.dup

    expect(instance.same_options?(opts)).to be(true)
    expect(instance.same_options?(opts.merge(extra: 'value'))).to be(false)
  end

  it 'handles non-hash arguments in same_options?' do
    instance = Class.new { extend TocDoc::Configurable }
    expect(instance.same_options?(instance.options)).to be(true)
  end

  it 'returns false for an object that does not respond to to_hash' do
    instance = Class.new { extend TocDoc::Configurable }
    non_hash = Object.new
    expect(instance.same_options?(non_hash)).to be(false)
  end

  describe '#per_page=' do
    subject(:instance) { Class.new { extend TocDoc::Configurable } }

    it 'emits a warning to stderr when the value exceeds MAX_PER_PAGE' do
      expect { instance.per_page = 99 }
        .to output(/\[TocDoc\] per_page 99 exceeds MAX_PER_PAGE/).to_stderr
    end

    it 'does not emit a warning when the value is within MAX_PER_PAGE' do
      expect { instance.per_page = 10 }.not_to output.to_stderr
    end
  end

  describe '#pagination_depth=' do
    subject(:instance) { Class.new { extend TocDoc::Configurable } }

    it 'accepts non-negative values without warning' do
      expect { instance.pagination_depth = 3 }.not_to output.to_stderr
      expect(instance.pagination_depth).to eq(3)
    end

    it 'clamps negative values to 0 with a warning' do
      expect { instance.pagination_depth = -1 }
        .to output(/\[TocDoc\] pagination_depth -1 is negative; clamped to 0/).to_stderr
      expect(instance.pagination_depth).to eq(0)
    end

    it 'accepts 0 without warning' do
      expect { instance.pagination_depth = 0 }.not_to output.to_stderr
      expect(instance.pagination_depth).to eq(0)
    end
  end

  describe 'rate_limit key' do
    subject(:instance) { Class.new { extend TocDoc::Configurable } }

    it 'is present in VALID_CONFIG_KEYS' do
      expect(described_class.keys).to include(:rate_limit)
    end

    it 'defaults to nil after reset' do
      expect(instance.rate_limit).to be_nil
    end
  end

  describe 'cache key' do
    subject(:instance) { Class.new { extend TocDoc::Configurable } }

    it 'is present in VALID_CONFIG_KEYS' do
      expect(described_class.keys).to include(:cache)
    end

    it 'defaults to nil after reset' do
      expect(instance.cache).to be_nil
    end
  end
end
