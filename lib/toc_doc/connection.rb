# frozen_string_literal: true

require 'faraday'

module TocDoc
  # Faraday-based connection and request helpers shared by clients.
  module Connection
    attr_accessor :last_response

    private

    def get(path, options = {})
      request(:get, path, nil, options)
    end

    def post(path, data = nil, options = {})
      request(:post, path, data, options)
    end

    def put(path, data = nil, options = {})
      request(:put, path, data, options)
    end

    def patch(path, data = nil, options = {})
      request(:patch, path, data, options)
    end

    def delete(path, options = {})
      request(:delete, path, nil, options)
    end

    def head(path, options = {})
      request(:head, path, nil, options)
    end

    # Memoized Faraday connection configured from configurable options.
    def agent
      @agent ||= Faraday.new(api_endpoint, faraday_options) do |conn|
        configure_faraday_headers(conn)
      end
    end

    def faraday_options
      opts = connection_options.dup
      opts[:builder] = middleware if middleware
      opts
    end

    def configure_faraday_headers(conn)
      conn.headers['Accept']       = default_media_type
      conn.headers['Content-Type'] = default_media_type
      conn.headers['User-Agent']   = user_agent
    end

    # Returns a boolean based on the last HTTP response status.
    def boolean_from_response(method, path, options = {})
      request(method, path, nil, options)
      status = last_response&.status

      case status
      when 200..299
        true
      when 404
        false
      else
        false
      end
    end

    # Core request helper used by all HTTP verbs.
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
    # Supports `:query` and `:headers` keys explicitly; otherwise treats
    # remaining keys as query params.
    def parse_query_and_convenience_headers(options)
      return [{}, {}] if options.nil? || options.empty?

      opts = options.dup
      explicit_query = opts.delete(:query)
      explicit_headers = opts.delete(:headers) || {}

      query = explicit_query || opts

      [query || {}, explicit_headers]
    end
  end
end
