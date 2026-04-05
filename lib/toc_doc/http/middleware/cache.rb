# frozen_string_literal: true

require 'uri'
require 'toc_doc/cache/memory_store'

module TocDoc
  module Middleware
    # Faraday middleware that caches successful GET responses.
    #
    # Cache hits bypass all downstream middleware (retry, rate-limiting, JSON
    # parsing, and the HTTP adapter).  The cached body is the already-parsed
    # object returned by the JSON middleware on the original miss.
    #
    # Only GET requests with 200 responses are cached.  All other verbs and
    # non-200 responses flow through normally.
    #
    # The cache key is built from the full URL with query parameters sorted for
    # determinism.
    #
    # Stack position (outermost first): RaiseError > Cache > Logging > Retry >
    # RateLimiter > JSON > Adapter
    #
    # @example
    #   store = TocDoc::Cache::MemoryStore.new
    #   builder.use TocDoc::Middleware::Cache, store: store, ttl: 300
    class Cache < Faraday::Middleware
      # @param app [#call] the next middleware in the stack
      # @param store [#read, #write] a cache store (MemoryStore or AS-compatible)
      # @param ttl [Numeric] TTL in seconds for cached responses (default: 300)
      def initialize(app, store:, ttl: 300)
        super(app)
        @store = store
        @ttl   = ttl
      end

      # Serves from cache on hit; fetches and caches on miss.
      #
      # @param env [Faraday::Env] the request environment
      # @return [Faraday::Response]
      def call(env)
        return @app.call(env) unless env[:method] == :get

        cache_key = build_key(env)
        cached = @store.read(cache_key)
        return cached_response(env, cached) if cached

        @app.call(env).on_complete do |response_env|
          next unless response_env.status == 200

          @store.write(cache_key, response_env.body, expires_in: @ttl)
        end
      end

      private

      def build_key(env)
        uri = env.url.dup
        if uri.query
          sorted_query = URI.decode_www_form(uri.query).sort.map { |k, v| "#{k}=#{v}" }.join('&')
          uri.query = sorted_query
        end
        "tocdoc:get:#{uri}"
      end

      def cached_response(env, body)
        env.status = 200
        env.body   = body
        Faraday::Response.new(env)
      end
    end
  end
end
