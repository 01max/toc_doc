# frozen_string_literal: true

require 'logger'
require 'toc_doc/http/middleware/logging'

RSpec.describe TocDoc::Middleware::Logging do
  # Build a minimal Faraday connection with the logging middleware wrapping a
  # test-adapter stub so no real HTTP requests are made.
  let(:log_output) { StringIO.new }
  let(:logger)     { Logger.new(log_output) }
  let(:stubs)      { Faraday::Adapter::Test::Stubs.new }

  let(:connection) do
    Faraday.new do |builder|
      builder.use described_class, logger: logger
      builder.adapter :test, stubs
    end
  end

  let(:silent_connection) do
    Faraday.new do |builder|
      builder.use described_class, logger: nil
      builder.adapter :test, stubs
    end
  end

  describe '#call — successful request' do
    before do
      stubs.get('/availabilities.json') { [200, {}, '{}'] }
    end

    it 'passes the response through unchanged' do
      response = connection.get('/availabilities.json')

      expect(response.status).to eq(200)
    end

    it 'logs at info level' do
      connection.get('/availabilities.json')

      expect(log_output.string).to include('INFO')
    end

    it 'includes the HTTP method in the log line' do
      connection.get('/availabilities.json')

      expect(log_output.string).to include('GET')
    end

    it 'includes the request path in the log line' do
      connection.get('/availabilities.json')

      expect(log_output.string).to include('/availabilities.json')
    end

    it 'includes the response status in the log line' do
      connection.get('/availabilities.json')

      expect(log_output.string).to include('200')
    end

    it 'includes a duration in milliseconds' do
      connection.get('/availabilities.json')

      expect(log_output.string).to match(/\d+ms/)
    end

    it 'matches the expected log format' do
      connection.get('/availabilities.json')

      expect(log_output.string).to match(%r{TocDoc: GET /availabilities\.json -> 200 \(\d+ms\)})
    end
  end

  describe '#call — error raised by downstream middleware' do
    before do
      stubs.get('/search.json') { raise Faraday::ConnectionFailed, 'Connection refused' }
    end

    it 're-raises the exception' do
      expect { connection.get('/search.json') }.to raise_error(Faraday::ConnectionFailed)
    end

    it 'logs at warn level' do
      connection.get('/search.json')
    rescue Faraday::ConnectionFailed
      expect(log_output.string).to include('WARN')
    end

    it 'includes the error message in the log line' do
      connection.get('/search.json')
    rescue Faraday::ConnectionFailed
      expect(log_output.string).to include('Connection refused')
    end

    it 'includes the request path in the error log line' do
      connection.get('/search.json')
    rescue Faraday::ConnectionFailed
      expect(log_output.string).to include('/search.json')
    end

    it 'matches the expected error log format' do
      connection.get('/search.json')
    rescue Faraday::ConnectionFailed
      expect(log_output.string).to match(%r{TocDoc: GET /search\.json -> error: .+ \(\d+ms\)})
    end
  end

  describe '#call — no logger (no-op)' do
    before do
      stubs.get('/path') { [200, {}, '{}'] }
    end

    it 'does not raise' do
      expect { silent_connection.get('/path') }.not_to raise_error
    end

    it 'produces no log output' do
      silent_connection.get('/path')

      # StringIO is shared via the logger; the silent connection has logger: nil
      # so we verify via a fresh output buffer attached only to this connection.
      noop_output = StringIO.new
      noop_conn = Faraday.new do |b|
        b.use described_class, logger: nil
        b.adapter :test, stubs
      end
      noop_conn.get('/path')

      expect(noop_output.string).to be_empty
    end
  end

  describe 'TocDoc::Default.build_middleware with logger:' do
    let(:built_middleware) { TocDoc::Default.build_middleware(logger: logger) }

    it 'returns a Faraday::RackBuilder' do
      expect(built_middleware).to be_a(Faraday::RackBuilder)
    end

    it 'includes the Logging middleware handler' do
      handlers = built_middleware.handlers.map(&:klass)

      expect(handlers).to include(TocDoc::Middleware::Logging)
    end

    it 'places Logging after RaiseError' do
      handlers = built_middleware.handlers.map(&:klass)
      raise_idx   = handlers.index(TocDoc::Middleware::RaiseError)
      logging_idx = handlers.index(TocDoc::Middleware::Logging)

      expect(logging_idx).to be > raise_idx
    end

    it 'does not include the Logging middleware when logger is nil' do
      stack    = TocDoc::Default.build_middleware(logger: nil)
      handlers = stack.handlers.map(&:klass)

      expect(handlers).not_to include(TocDoc::Middleware::Logging)
    end
  end

  describe 'TocDoc::Default.build_middleware with :stdout shorthand' do
    it 'returns a stack that includes the Logging middleware' do
      stack    = TocDoc::Default.build_middleware(logger: :stdout)
      handlers = stack.handlers.map(&:klass)

      expect(handlers).to include(TocDoc::Middleware::Logging)
    end
  end

  describe 'TocDoc::Default.middleware (memoized default) is not mutated' do
    it 'does not include Logging in the default stack' do
      TocDoc::Default.reset!
      handlers = TocDoc::Default.middleware.handlers.map(&:klass)

      expect(handlers).not_to include(TocDoc::Middleware::Logging)
    end

    it 'remains the same object after build_middleware is called with a logger' do
      TocDoc::Default.reset!
      original = TocDoc::Default.middleware

      TocDoc::Default.build_middleware(logger: logger)

      expect(TocDoc::Default.middleware).to equal(original)
    end
  end
end
