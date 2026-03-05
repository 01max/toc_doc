# frozen_string_literal: true

RSpec.describe TocDoc do
  it 'has a version number' do
    expect(TocDoc::VERSION).not_to be nil
  end

  it 'allows module-level configuration and exposes options' do
    TocDoc.reset!

    TocDoc.configure do |config|
      config.api_endpoint = 'https://configured.example'
      config.per_page = 10
    end

    expect(TocDoc.options[:api_endpoint]).to eq('https://configured.example')
    expect(TocDoc.options[:per_page]).to eq(10)
  ensure
    TocDoc.reset!
  end

  describe '.setup' do
    it 'yields self for configuration and returns the client' do
      TocDoc.reset!
      client = TocDoc.setup { |config| config.per_page = 11 }
      expect(client).to be_a(TocDoc::Client)
      expect(TocDoc.options[:per_page]).to eq(11)
    ensure
      TocDoc.reset!
    end
  end

  describe 'method delegation' do
    it 'raises NoMethodError for methods the client does not respond to' do
      expect { TocDoc.totally_undefined_method_xyz }.to raise_error(NoMethodError)
    end

    it 'reports respond_to? correctly for delegated methods' do
      expect(TocDoc.respond_to?(:availabilities)).to be true
      expect(TocDoc.respond_to?(:totally_undefined_method_xyz)).to be false
    end
  end

  it 'provides a memoized client reflecting current options' do
    TocDoc.reset!
    TocDoc.configure { |config| config.per_page = 7 }

    client = TocDoc.client
    expect(client.per_page).to eq(7)
    expect(TocDoc.client).to be(client)

    TocDoc.configure { |config| config.per_page = 9 }
    new_client = TocDoc.client

    expect(new_client).not_to be(client)
    expect(new_client.per_page).to eq(9)
  ensure
    TocDoc.reset!
  end
end
