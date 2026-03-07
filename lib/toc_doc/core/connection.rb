# frozen_string_literal: true

require 'faraday'

module TocDoc
  # Faraday-based HTTP connection and request helpers.
  #
  # Included into {TocDoc::Client} to provide low-level HTTP verbs
  # (`get`, `post`, `put`, `patch`, `delete`, `head`), a memoised
  # Faraday connection, pagination support, and response tracking.
  #
  # {#get} and {#paginate} are public so that model classes (e.g.
  # {TocDoc::Availability}) can call them via `TocDoc.client`; all other
  # HTTP verb methods remain private.
  #
  # @see TocDoc::Client
  module Connection
    # The most-recent raw Faraday response, set after every request.
    #
    # @return [Faraday::Response, nil]
    attr_accessor :last_response

    private

    # Perform a GET request.
    #
    # @param path [String] API path (relative to {Configurable#api_endpoint})
    # @param options [Hash] query / header options forwarded to {#request}
    # @return [Object] parsed response body
    def get(path, options = {})
      request(:get, path, nil, options)
    end

    # Perform a POST request.
    #
    # @param path [String] API path
    # @param data [Object, nil] request body
    # @param options [Hash] query / header options
    # @return [Object] parsed response body
    def post(path, data = nil, options = {})
      request(:post, path, data, options)
    end

    # Perform a PUT request.
    #
    # @param path [String] API path
    # @param data [Object, nil] request body
    # @param options [Hash] query / header options
    # @return [Object] parsed response body
    def put(path, data = nil, options = {})
      request(:put, path, data, options)
    end

    # Perform a PATCH request.
    #
    # @param path [String] API path
    # @param data [Object, nil] request body
    # @param options [Hash] query / header options
    # @return [Object] parsed response body
    def patch(path, data = nil, options = {})
      request(:patch, path, data, options)
    end

    # Perform a DELETE request.
    #
    # @param path [String] API path
    # @param options [Hash] query / header options
    # @return [Object] parsed response body
    def delete(path, options = {})
      request(:delete, path, nil, options)
    end

    # Perform a HEAD request.
    #
    # @param path [String] API path
    # @param options [Hash] query / header options
    # @return [Object] parsed response body
    def head(path, options = {})
      request(:head, path, nil, options)
    end

    # Memoised Faraday connection configured from the current
    # {Configurable} options.
    #
    # @return [Faraday::Connection]
    def agent
      @agent ||= Faraday.new(api_endpoint, faraday_options) do |conn|
        configure_faraday_headers(conn)
      end
    end

    # @return [Hash] merged Faraday connection options
    def faraday_options
      opts = connection_options.dup
      opts[:builder] = middleware if middleware
      opts
    end

    # Sets default HTTP headers on a Faraday connection.
    #
    # @param conn [Faraday::Connection]
    # @return [void]
    def configure_faraday_headers(conn)
      conn.headers['Accept']       = default_media_type
      conn.headers['Content-Type'] = default_media_type
      conn.headers['User-Agent']   = user_agent
    end

    # Performs a paginated GET, accumulating results across pages.
    #
    # When {Configurable#auto_paginate} is disabled or no block is given,
    # behaves exactly like {#get}.
    #
    # When +auto_paginate+ is +true+ **and** a block is provided, the block is
    # yielded after every page fetch — including the first — with
    # +(accumulator, last_response)+.  The block must:
    #
    # 1. Detect whether it is a continuation call by comparing object identity:
    #    `acc.equal?(last_response.body)` is `true` only on the first yield,
    #    when the accumulator *is* the first-page body.  On subsequent yields
    #    the block should merge `last_response.body` into `acc`.
    # 2. Return a Hash of options to pass to the next {#get} call (pagination
    #    continues), or `nil` / `false` to halt.
    #
    # @param path [String] the API path
    # @param options [Hash] query / header options forwarded to every request
    # @yieldparam acc [Object] the growing accumulator (first-page body initially)
    # @yieldparam last_response [Faraday::Response] the most-recent raw response
    # @yieldreturn [Hash, nil] next-page options, or +nil+/+false+ to halt
    # @return [Object] the fully-accumulated response body
    def paginate(path, options = {}, &)
      data = get(path, options)
      return data unless block_given? && auto_paginate

      loop do
        next_options = yield(data, last_response)
        break unless next_options

        get(path, next_options)
      end

      data
    end

    # Returns a boolean based on the HTTP response status of the given request.
    #
    # @param method [Symbol] HTTP verb (e.g. +:get+, +:head+)
    # @param path [String] API path
    # @param options [Hash] query / header options
    # @return [Boolean] +true+ when the response is 2xx
    def boolean_from_response?(method, path, options = {})
      request(method, path, nil, options)
      status = last_response&.status

      (200..299).cover?(status)
    end

    # Core request helper used by all HTTP verb methods.
    #
    # @param method [Symbol] HTTP verb
    # @param path [String] API path
    # @param data [Object, nil] optional request body
    # @param options [Hash] query / header options
    # @return [Object] parsed response body
    def request(method, path, data = nil, options = {})
      query, headers = parse_query_and_convenience_headers(options)

      response = agent.public_send(method) do |req|
        req.url(path, query)
        req.headers.update(headers) unless headers.empty?
        req.body = data if data
      end

      self.last_response = response
      response.body
    end

    # Splits a generic options hash into query params and headers.
    #
    # Supports explicit `:query` and `:headers` keys; otherwise treats
    # remaining keys as query params.
    #
    # @param options [Hash] combined query/header options
    # @return [Array(Hash, Hash)] a two-element array of `[query, headers]`
    def parse_query_and_convenience_headers(options)
      return [{}, {}] if options.nil? || options.empty?

      opts = options.dup
      explicit_query = opts.delete(:query)
      explicit_headers = opts.delete(:headers) || {}

      query = explicit_query || opts

      [query || {}, explicit_headers]
    end

    public :get, :paginate
  end
end
