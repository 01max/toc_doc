# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

require 'toc_doc/http/middleware/raise_error'
require 'toc_doc/http/middleware/logging'
require 'toc_doc/http/middleware/rate_limiter'
require 'toc_doc/http/middleware/cache'
require 'toc_doc/http/rate_limiter/token_bucket'
require 'toc_doc/cache/memory_store'

module TocDoc
  # Provides sensible default values for every configurable option.
  #
  # Each value can be overridden per-environment via the corresponding `TOCDOC_*`
  # environment variable (see individual methods).
  #
  # @see TocDoc::Configurable
  module Default
    # @return [String] the default API base URL
    API_ENDPOINT = 'https://www.doctolib.fr'

    # @return [String] the default User-Agent header
    USER_AGENT   = "TocDoc Ruby Gem #{TocDoc::VERSION}".freeze

    # @return [String] the default Accept / Content-Type media type
    MEDIA_TYPE   = 'application/json'

    # @return [Integer] the default number of results per page
    PER_PAGE       = 15

    # @return [Integer] the default number of +next_slot+ hops to follow
    PAGINATION_DEPTH = 1

    # @return [Integer] the hard upper limit for per_page
    MAX_PER_PAGE   = 15

    # @return [Integer] the default maximum number of retries
    MAX_RETRY      = 3

    # @return [Integer] the default TCP connect timeout in seconds
    CONNECT_TIMEOUT = 5

    # @return [Integer] the default read (response) timeout in seconds
    READ_TIMEOUT    = 10

    class << self
      # Returns a hash of all default configuration values, suitable for
      # passing to {TocDoc::Configurable#reset!}.
      #
      # @return [Hash{Symbol => Object}]
      def options
        { api_endpoint:, user_agent:, default_media_type:, per_page:,
          middleware:, connection_options:, connect_timeout:, read_timeout:,
          logger: nil, pagination_depth:, rate_limit: nil, cache: nil }
      end

      # The base API endpoint URL.
      #
      # Falls back to the `TOCDOC_API_ENDPOINT` environment variable, then
      # {API_ENDPOINT}.
      #
      # @return [String]
      def api_endpoint
        ENV.fetch('TOCDOC_API_ENDPOINT', API_ENDPOINT)
      end

      # The User-Agent header sent with every request.
      #
      # Falls back to the `TOCDOC_USER_AGENT` environment variable, then
      # {USER_AGENT}.
      #
      # @return [String]
      def user_agent
        ENV.fetch('TOCDOC_USER_AGENT', USER_AGENT)
      end

      # The Accept / Content-Type media type.
      #
      # Falls back to the `TOCDOC_MEDIA_TYPE` environment variable, then
      # {MEDIA_TYPE}.
      #
      # @return [String]
      def default_media_type
        ENV.fetch('TOCDOC_MEDIA_TYPE', MEDIA_TYPE)
      end

      # Number of results per page, clamped to {MAX_PER_PAGE}.
      #
      # Falls back to the `TOCDOC_PER_PAGE` environment variable, then
      # {PER_PAGE}.
      #
      # @return [Integer]
      def per_page
        [Integer(ENV.fetch('TOCDOC_PER_PAGE', PER_PAGE), 10), MAX_PER_PAGE].min
      rescue ArgumentError
        PER_PAGE
      end

      # Number of +next_slot+ hops to follow automatically.
      #
      # Falls back to the `TOCDOC_PAGINATION_DEPTH` environment variable, then
      # {PAGINATION_DEPTH}.  Negative ENV values are clamped to 0.
      #
      # @return [Integer]
      def pagination_depth
        depth = Integer(ENV.fetch('TOCDOC_PAGINATION_DEPTH', PAGINATION_DEPTH), 10)
        [depth, 0].max
      rescue ArgumentError
        PAGINATION_DEPTH
      end

      # The default (memoized) Faraday middleware stack, built without a logger.
      #
      # Stack order (outermost first): RaiseError, retry, JSON parsing, adapter.
      # RaiseError is outermost so it wraps retry and maps the final response or
      # re-raised transport exception into a typed {TocDoc::Error}.
      #
      # @return [Faraday::RackBuilder]
      def middleware
        @middleware ||= build_middleware
      end

      # Builds a Faraday middleware stack, optionally injecting a logger,
      # rate limiter, and response cache.
      #
      # Stack order (outermost first):
      #   RaiseError > [Cache] > [Logging] > Retry > [RateLimiter] > JSON > Adapter
      #
      # @param logger [Logger, :stdout, nil] the logger to inject; +nil+ omits logging
      # @param rate_limit [Numeric, Hash, nil] rate-limit config (see {.resolve_rate_limit})
      # @param cache [Symbol, Hash, Object, nil] cache config (see {.resolve_cache})
      # @return [Faraday::RackBuilder]
      def build_middleware(logger: nil, rate_limit: nil, cache: nil)
        resolved_logger = resolve_logger(logger)
        resolved_bucket = resolve_rate_limit(rate_limit)
        resolved_cache  = resolve_cache(cache)
        Faraday::RackBuilder.new do |builder|
          builder.use TocDoc::Middleware::RaiseError
          if resolved_cache
            builder.use TocDoc::Middleware::Cache,
                        store: resolved_cache[:store],
                        ttl: resolved_cache[:ttl]
          end
          builder.use TocDoc::Middleware::Logging, logger: resolved_logger if resolved_logger
          builder.request :retry, retry_options
          builder.use TocDoc::Middleware::RateLimiter, bucket: resolved_bucket if resolved_bucket
          builder.response :json, content_type: /\bjson$/
          builder.adapter Faraday.default_adapter
        end
      end

      # Default Faraday connection options (empty by default).
      #
      # @return [Hash]
      def connection_options
        @connection_options ||= {}
      end

      # The TCP connect timeout in seconds.
      #
      # Falls back to the `TOCDOC_CONNECT_TIMEOUT` environment variable, then
      # {CONNECT_TIMEOUT}.  Invalid ENV values fall back to {CONNECT_TIMEOUT}.
      #
      # @return [Integer]
      def connect_timeout
        Integer(ENV.fetch('TOCDOC_CONNECT_TIMEOUT', CONNECT_TIMEOUT), 10)
      rescue ArgumentError
        CONNECT_TIMEOUT
      end

      # The read (response) timeout in seconds.
      #
      # Falls back to the `TOCDOC_READ_TIMEOUT` environment variable, then
      # {READ_TIMEOUT}.  Invalid ENV values fall back to {READ_TIMEOUT}.
      #
      # @return [Integer]
      def read_timeout
        Integer(ENV.fetch('TOCDOC_READ_TIMEOUT', READ_TIMEOUT), 10)
      rescue ArgumentError
        READ_TIMEOUT
      end

      # Clears all memoized values so the next call to {.middleware} and
      # {.connection_options} rebuilds them from scratch.
      #
      # Called by {TocDoc::Configurable#reset!} to ensure each reset produces a
      # fresh middleware stack rather than reusing a stale memoized instance.
      #
      # @return [void]
      def reset!
        @middleware = nil
        @connection_options = nil
      end

      private

      def resolve_logger(logger)
        case logger
        when :stdout
          require 'logger'
          Logger.new($stdout, progname: 'TocDoc')
        when nil, false
          nil
        else
          logger
        end
      end

      def resolve_rate_limit(config)
        case config
        when nil, false
          nil
        when Numeric
          TocDoc::RateLimiter::TokenBucket.new(rate: config, interval: 1.0)
        when Hash
          TocDoc::RateLimiter::TokenBucket.new(**config)
        end
      end

      def resolve_cache(config)
        case config
        when nil, false
          nil
        when :memory
          { store: TocDoc::Cache::MemoryStore.new, ttl: 300 }
        when Hash
          store = config[:store]
          store = TocDoc::Cache::MemoryStore.new if store.nil? || store == :memory
          { store: store, ttl: config.fetch(:ttl, 300) }
        else
          { store: config, ttl: 300 }
        end
      end

      def retry_options
        {
          max: retry_max,
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504],
          methods: %i[get head options]
        }
      end

      def retry_max
        Integer(ENV.fetch('TOCDOC_RETRY_MAX', MAX_RETRY), 10)
      rescue ArgumentError
        MAX_RETRY
      end
    end
  end
end
