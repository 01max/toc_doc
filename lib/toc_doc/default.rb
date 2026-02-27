# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

module TocDoc
  # Default configuration values and helpers for TocDoc.
  module Default
    API_ENDPOINT = 'https://www.doctolib.fr'
    USER_AGENT   = "TocDoc Ruby Gem #{TocDoc::VERSION}".freeze
    MEDIA_TYPE   = 'application/json'
    PER_PAGE     = 5
    MAX_RETRY    = 3

    class << self
      # Returns a hash of default configuration options.
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

      def api_endpoint
        ENV.fetch('TOCDOC_API_ENDPOINT', API_ENDPOINT)
      end

      def user_agent
        ENV.fetch('TOCDOC_USER_AGENT', USER_AGENT)
      end

      def default_media_type
        ENV.fetch('TOCDOC_MEDIA_TYPE', MEDIA_TYPE)
      end

      def per_page
        Integer(ENV.fetch('TOCDOC_PER_PAGE', PER_PAGE), 10)
      rescue ArgumentError
        PER_PAGE
      end

      # Default Faraday middleware stack: retry + error handling + adapter.
      def middleware
        @middleware ||= build_middleware
      end

      # Default Faraday connection options.
      def connection_options
        @connection_options ||= {}
      end

      private

      def build_middleware
        Faraday::RackBuilder.new do |builder|
          builder.request :retry, retry_options
          builder.use TocDoc::Middleware::RaiseError
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
