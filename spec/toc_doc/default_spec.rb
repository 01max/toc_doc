# frozen_string_literal: true

RSpec.describe TocDoc::Default do
  around do |example|
    original_env = ENV.to_hash
    begin
      ENV.delete('TOCDOC_API_ENDPOINT')
      ENV.delete('TOCDOC_USER_AGENT')
      ENV.delete('TOCDOC_MEDIA_TYPE')
      ENV.delete('TOCDOC_PER_PAGE')
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
  end

  it 'respects ENV fallbacks' do
    ENV['TOCDOC_API_ENDPOINT'] = 'https://www.doctolib.de'
    ENV['TOCDOC_USER_AGENT'] = 'Custom UA'
    ENV['TOCDOC_MEDIA_TYPE'] = 'application/xml'
    ENV['TOCDOC_PER_PAGE'] = '42'

    expect(described_class.api_endpoint).to eq('https://www.doctolib.de')
    expect(described_class.user_agent).to eq('Custom UA')
    expect(described_class.default_media_type).to eq('application/xml')
    expect(described_class.per_page).to eq(42)
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

  it 'ignores unknown TOCDOC_* ENV keys' do
    baseline = described_class.options.dup

    ENV['TOCDOC_UNKNOWN_KEY'] = 'ignored-value'

    expect(described_class.options).to eq(baseline)
  end
end
