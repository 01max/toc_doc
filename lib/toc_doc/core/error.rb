# frozen_string_literal: true

module TocDoc
  # Base error class for all TocDoc errors.
  #
  # Inherits from +StandardError+ so consumers can rescue +TocDoc::Error+
  # without any knowledge of Faraday or other internal HTTP details.
  #
  # @example Rescuing TocDoc errors
  #   begin
  #     TocDoc.availabilities(visit_motive_ids: 0, agenda_ids: 0)
  #   rescue TocDoc::Error => e
  #     puts e.message
  #   end
  class Error < StandardError; end

  # Raised when a network-level failure occurs before an HTTP response is
  # received (e.g. DNS resolution failure, connection refused, timeout).
  #
  # The original low-level exception is available via Ruby's built-in
  # +#cause+ mechanism — no extra attribute needed.
  #
  # @example
  #   rescue TocDoc::ConnectionError => e
  #     puts e.cause  # original Faraday::ConnectionFailed, etc.
  class ConnectionError < Error; end

  # Raised when an HTTP response is received but indicates an error.
  #
  # Carries the raw response details so callers can act on them without
  # needing to reach into Faraday internals.
  #
  # @example
  #   rescue TocDoc::ResponseError => e
  #     puts e.status   # => 404
  #     puts e.body     # => '{"error":"not found"}'
  #     puts e.headers  # => {"content-type"=>"application/json"}
  class ResponseError < Error
    # @return [Integer] the HTTP status code
    attr_reader :status

    # @return [String, nil] the raw response body
    attr_reader :body

    # @return [Hash, nil] the response headers
    attr_reader :headers

    # @param status [Integer] the HTTP status code
    # @param body [String, nil] the raw response body
    # @param headers [Hash, nil] the response headers
    # @param message [String, nil] optional override for the error message;
    #   defaults to +"HTTP #{status}"+
    def initialize(status:, body: nil, headers: nil, message: nil)
      @status = status
      @body = body
      @headers = headers
      super(message || "HTTP #{status}")
    end
  end

  # Raised for 4xx client error responses.
  #
  # @see ResponseError
  class ClientError < ResponseError; end

  # Raised for HTTP 400 Bad Request responses.
  #
  # @see ClientError
  class BadRequest < ClientError; end

  # Raised for HTTP 404 Not Found responses.
  #
  # @see ClientError
  class NotFound < ClientError; end

  # Raised for HTTP 422 Unprocessable Entity responses.
  #
  # @see ClientError
  class UnprocessableEntity < ClientError; end

  # Raised for HTTP 429 Too Many Requests responses.
  #
  # @see ClientError
  class TooManyRequests < ClientError; end

  # Raised for 5xx server error responses.
  #
  # @see ResponseError
  class ServerError < ResponseError; end
end
