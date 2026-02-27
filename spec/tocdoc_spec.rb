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
