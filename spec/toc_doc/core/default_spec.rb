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
      ENV.delete('TOCDOC_PAGINATION_DEPTH')
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

  describe '.pagination_depth' do
    it 'returns PAGINATION_DEPTH by default' do
      expect(described_class.pagination_depth).to eq(TocDoc::Default::PAGINATION_DEPTH)
    end

    it 'returns the integer value of TOCDOC_PAGINATION_DEPTH when set' do
      ENV['TOCDOC_PAGINATION_DEPTH'] = '3'
      expect(described_class.pagination_depth).to eq(3)
    end

    it 'clamps negative ENV values to 0' do
      ENV['TOCDOC_PAGINATION_DEPTH'] = '-5'
      expect(described_class.pagination_depth).to eq(0)
    end

    it 'falls back to PAGINATION_DEPTH on invalid ENV value' do
      ENV['TOCDOC_PAGINATION_DEPTH'] = 'bad'
      expect(described_class.pagination_depth).to eq(TocDoc::Default::PAGINATION_DEPTH)
    end
  end

  describe '.build_middleware' do
    it 'returns a Faraday::RackBuilder' do
      expect(described_class.build_middleware).to be_a(Faraday::RackBuilder)
    end

    it 'includes RaiseError as the first handler' do
      stack = described_class.build_middleware
      expect(stack.handlers.first.klass).to eq(TocDoc::Middleware::RaiseError)
    end

    context 'with rate_limit as a Numeric' do
      it 'inserts a RateLimiter middleware' do
        stack = described_class.build_middleware(rate_limit: 5)
        klasses = stack.handlers.map(&:klass)
        expect(klasses).to include(TocDoc::Middleware::RateLimiter)
      end

      it 'positions RateLimiter between Retry and JSON' do
        stack = described_class.build_middleware(rate_limit: 5)
        klasses = stack.handlers.map(&:klass)
        retry_idx     = klasses.index(Faraday::Retry::Middleware) ||
                        klasses.index { |k| k.name&.include?('Retry') }
        rate_idx      = klasses.index(TocDoc::Middleware::RateLimiter)
        expect(rate_idx).to be > retry_idx
      end
    end

    context 'with rate_limit as a Hash' do
      it 'inserts a RateLimiter middleware with the given options' do
        stack = described_class.build_middleware(rate_limit: { rate: 2, interval: 1.0 })
        klasses = stack.handlers.map(&:klass)
        expect(klasses).to include(TocDoc::Middleware::RateLimiter)
      end
    end

    context 'without rate_limit' do
      it 'does not insert a RateLimiter middleware' do
        stack = described_class.build_middleware
        klasses = stack.handlers.map(&:klass)
        expect(klasses).not_to include(TocDoc::Middleware::RateLimiter)
      end
    end

    context 'with cache: :memory' do
      it 'inserts a Cache middleware' do
        stack = described_class.build_middleware(cache: :memory)
        klasses = stack.handlers.map(&:klass)
        expect(klasses).to include(TocDoc::Middleware::Cache)
      end

      it 'positions Cache before Logging' do
        stack = described_class.build_middleware(cache: :memory, logger: :stdout)
        klasses = stack.handlers.map(&:klass)
        cache_idx   = klasses.index(TocDoc::Middleware::Cache)
        logging_idx = klasses.index(TocDoc::Middleware::Logging)
        expect(cache_idx).to be < logging_idx
      end
    end

    context 'without cache' do
      it 'does not insert a Cache middleware' do
        stack = described_class.build_middleware
        klasses = stack.handlers.map(&:klass)
        expect(klasses).not_to include(TocDoc::Middleware::Cache)
      end
    end

    context 'with all features active' do
      it 'produces the correct stack order: RaiseError > Cache > Logging > Retry > RateLimiter > JSON > Adapter' do
        stack = described_class.build_middleware(logger: :stdout, rate_limit: 5, cache: :memory)
        klasses = stack.handlers.map(&:klass)
        raise_idx  = klasses.index(TocDoc::Middleware::RaiseError)
        cache_idx  = klasses.index(TocDoc::Middleware::Cache)
        log_idx    = klasses.index(TocDoc::Middleware::Logging)
        retry_idx  = klasses.index { |k| k.name&.include?('Retry') }
        rate_idx   = klasses.index(TocDoc::Middleware::RateLimiter)
        expect(raise_idx).to be < cache_idx
        expect(cache_idx).to be < log_idx
        expect(log_idx).to be < retry_idx
        expect(retry_idx).to be < rate_idx
      end
    end
  end
end
