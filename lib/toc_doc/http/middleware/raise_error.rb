# frozen_string_literal: true

require 'faraday'

module TocDoc
  # @api private
  module Middleware
    # Faraday middleware that translates HTTP error responses and transport-level
    # failures into typed {TocDoc::Error} subclasses, keeping Faraday as an
    # internal implementation detail.
    #
    # Placed as the outermost middleware so the retry middleware operates on raw
    # Faraday exceptions and returns the final response after exhaustion.
    #
    # Two-pronged error mapping:
    # - +on_complete+: inspects the HTTP status and raises the appropriate
    #   {TocDoc::ResponseError} subclass for 4xx/5xx responses.
    # - +rescue+ in +call+: catches Faraday transport errors and raises
    #   {TocDoc::ConnectionError}.
    #
    # @see TocDoc::Error
    # @see TocDoc::ConnectionError
    # @see TocDoc::ResponseError
    class RaiseError < Faraday::Middleware
      # Maps specific HTTP status codes to their typed error classes.
      # Statuses not in this map fall back to {TocDoc::ClientError} (4xx) or
      # {TocDoc::ServerError} (5xx).
      #
      # @return [Hash{Integer => Class}]
      STATUS_MAP = {
        400 => TocDoc::BadRequest,
        404 => TocDoc::NotFound,
        422 => TocDoc::UnprocessableEntity,
        429 => TocDoc::TooManyRequests
      }.freeze

      # Executes the request, raises {TocDoc::ConnectionError} on transport
      # failures, and delegates HTTP error mapping to +on_complete+.
      #
      # @param env [Faraday::Env] the Faraday request environment
      # @return [Faraday::Response] the response on success
      # @raise [TocDoc::ConnectionError] on network/transport-level failures
      # @raise [TocDoc::ResponseError] on 4xx or 5xx HTTP responses
      def call(env)
        @app.call(env).on_complete do |response_env|
          on_complete(response_env)
        end
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError => e
        raise TocDoc::ConnectionError, e.message
      end

      private

      # Maps the HTTP status in +env+ to a typed {TocDoc::ResponseError} and
      # raises it. No-ops for non-error statuses.
      #
      # @param env [Faraday::Env] the completed response environment
      # @return [void]
      # @raise [TocDoc::ResponseError] for 4xx or 5xx status codes
      def on_complete(env)
        status  = env[:status]
        body    = env[:body]
        headers = env[:response_headers]

        error_class = error_class_for(status)
        raise error_class.new(status: status, body: body, headers: headers) if error_class
      end

      # Resolves the error class for a given HTTP status code.
      #
      # @param status [Integer] the HTTP status code
      # @return [Class, nil] the error class, or +nil+ if the status is not an error
      def error_class_for(status)
        if STATUS_MAP.key?(status)
          STATUS_MAP[status]
        elsif status >= 400 && status < 500
          TocDoc::ClientError
        elsif status >= 500
          TocDoc::ServerError
        end
      end
    end
  end
end
