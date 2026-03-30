# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

require 'toc_doc/http/middleware/raise_error'

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
        {
          api_endpoint: api_endpoint,
          user_agent: user_agent,
          default_media_type: default_media_type,
          per_page: per_page,
          middleware: middleware,
          connection_options: connection_options,
          connect_timeout: connect_timeout,
          read_timeout: read_timeout
        }
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

      # The default Faraday middleware stack.
      #
      # Stack order (outermost first): RaiseError, retry, JSON parsing, adapter.
      # RaiseError is outermost so it wraps retry and maps the final response or
      # re-raised transport exception into a typed {TocDoc::Error}.
      #
      # @return [Faraday::RackBuilder]
      def middleware
        @middleware ||= build_middleware
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

      def build_middleware
        Faraday::RackBuilder.new do |builder|
          builder.use TocDoc::Middleware::RaiseError
          builder.request :retry, retry_options
          builder.response :json, content_type: /\bjson$/
          builder.adapter Faraday.default_adapter
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
