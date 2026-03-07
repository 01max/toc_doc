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
          connection_options: connection_options
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
      # Includes retry logic, error raising, JSON parsing, and the default
      # adapter.
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

      private

      def build_middleware
        Faraday::RackBuilder.new do |builder|
          builder.request :retry, retry_options
          builder.use TocDoc::Middleware::RaiseError
          builder.response :raise_error
          builder.response :json, content_type: /\bjson$/
          builder.adapter Faraday.default_adapter
        end
      end

      def retry_options
        {
          max: Integer(ENV.fetch('TOCDOC_RETRY_MAX', MAX_RETRY), 10),
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504],
          methods: %i[get head options]
        }
      rescue ArgumentError
        retry_options_fallback
      end

      def retry_options_fallback
        {
          max: MAX_RETRY,
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504],
          methods: %i[get head options]
        }
      end
    end
  end
end
