# frozen_string_literal: true

RSpec.describe TocDoc::Default do
  around do |example|
    original_env = ENV.to_hash
    begin
      ENV.delete('TOCDOC_API_ENDPOINT')
      ENV.delete('TOCDOC_USER_AGENT')
      ENV.delete('TOCDOC_MEDIA_TYPE')
      ENV.delete('TOCDOC_PER_PAGE')
      ENV.delete('TOCDOC_AUTO_PAGINATE')
      ENV.delete('TOCDOC_CONNECT_TIMEOUT')
      ENV.delete('TOCDOC_READ_TIMEOUT')
      example.run
    ensure
      ENV.replace(original_env)
    end
  end

  it 'provides default options' do
    options = described_class.options

    expect(options[:api_endpoint]).to eq(TocDoc::Default::API_ENDPOINT)
    expect(options[:user_agent]).to eq(TocDoc::Default::USER_AGENT)
    expect(options[:default_media_type]).to eq(TocDoc::Default::MEDIA_TYPE)
    expect(options[:per_page]).to eq(TocDoc::Default::PER_PAGE)
    expect(options[:middleware]).not_to be_nil
    expect(options[:connection_options]).to eq({})
    expect(options[:connect_timeout]).to eq(TocDoc::Default::CONNECT_TIMEOUT)
    expect(options[:read_timeout]).to eq(TocDoc::Default::READ_TIMEOUT)
    expect(options).not_to have_key(:auto_paginate)
  end

  it 'respects ENV fallbacks' do
    ENV['TOCDOC_API_ENDPOINT'] = 'https://www.doctolib.de'
    ENV['TOCDOC_USER_AGENT'] = 'Custom UA'
    ENV['TOCDOC_MEDIA_TYPE'] = 'application/xml'
    ENV['TOCDOC_PER_PAGE'] = '10'

    expect(described_class.api_endpoint).to eq('https://www.doctolib.de')
    expect(described_class.user_agent).to eq('Custom UA')
    expect(described_class.default_media_type).to eq('application/xml')
    expect(described_class.per_page).to eq(10)
  end

  it 'caps per_page at MAX_PER_PAGE even from ENV' do
    ENV['TOCDOC_PER_PAGE'] = '42'

    expect(described_class.per_page).to eq(TocDoc::Default::MAX_PER_PAGE)
  end

  it 'uses defaults when ENV keys are missing' do
    ENV.delete('TOCDOC_API_ENDPOINT')
    ENV.delete('TOCDOC_USER_AGENT')
    ENV.delete('TOCDOC_MEDIA_TYPE')
    ENV.delete('TOCDOC_PER_PAGE')

    expect(described_class.api_endpoint).to eq(TocDoc::Default::API_ENDPOINT)
    expect(described_class.user_agent).to eq(TocDoc::Default::USER_AGENT)
    expect(described_class.default_media_type).to eq(TocDoc::Default::MEDIA_TYPE)
    expect(described_class.per_page).to eq(TocDoc::Default::PER_PAGE)
  end

  it 'falls back to default per_page on invalid ENV' do
    ENV['TOCDOC_PER_PAGE'] = 'invalid'

    expect(described_class.per_page).to eq(TocDoc::Default::PER_PAGE)
  end

  describe '.connect_timeout' do
    it 'returns the CONNECT_TIMEOUT constant by default' do
      expect(described_class.connect_timeout).to eq(TocDoc::Default::CONNECT_TIMEOUT)
    end

    it 'returns the integer value of TOCDOC_CONNECT_TIMEOUT when set' do
      ENV['TOCDOC_CONNECT_TIMEOUT'] = '30'

      expect(described_class.connect_timeout).to eq(30)
    end

    it 'falls back to CONNECT_TIMEOUT on invalid ENV value' do
      ENV['TOCDOC_CONNECT_TIMEOUT'] = 'not-a-number'

      expect(described_class.connect_timeout).to eq(TocDoc::Default::CONNECT_TIMEOUT)
    end
  end

  describe '.read_timeout' do
    it 'returns the READ_TIMEOUT constant by default' do
      expect(described_class.read_timeout).to eq(TocDoc::Default::READ_TIMEOUT)
    end

    it 'returns the integer value of TOCDOC_READ_TIMEOUT when set' do
      ENV['TOCDOC_READ_TIMEOUT'] = '60'

      expect(described_class.read_timeout).to eq(60)
    end

    it 'falls back to READ_TIMEOUT on invalid ENV value' do
      ENV['TOCDOC_READ_TIMEOUT'] = 'bad'

      expect(described_class.read_timeout).to eq(TocDoc::Default::READ_TIMEOUT)
    end
  end

  it 'ignores unknown TOCDOC_* ENV keys' do
    baseline = described_class.options.dup

    ENV['TOCDOC_UNKNOWN_KEY'] = 'ignored-value'

    expect(described_class.options).to eq(baseline)
  end

  describe '.reset!' do
    it 'produces a new middleware object on the next access' do
      original = described_class.middleware

      described_class.reset!

      expect(described_class.middleware).not_to equal(original)
    end

    it 'produces a new connection_options object on the next access' do
      original = described_class.connection_options

      described_class.reset!

      expect(described_class.connection_options).not_to equal(original)
    end
  end
end
