# frozen_string_literal: true

RSpec.describe TocDoc::Configurable do
  it 'lists valid configuration keys' do
    expect(described_class.keys).to include(*%i[api_endpoint user_agent middleware connection_options
                                                default_media_type per_page])
  end

  it 'resets to default options' do
    instance = Class.new { extend TocDoc::Configurable }
    instance.api_endpoint = 'https://override.example'

    expect { instance.reset! }.to change { instance.api_endpoint }.to(TocDoc::Default.api_endpoint)
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
end
