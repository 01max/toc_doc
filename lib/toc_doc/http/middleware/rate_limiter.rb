# frozen_string_literal: true

require 'toc_doc/http/rate_limiter/token_bucket'

module TocDoc
  module Middleware
    # Faraday middleware that enforces a client-side rate limit via a
    # {TocDoc::RateLimiter::TokenBucket}.
    #
    # Placed between the retry middleware and the JSON middleware so each retry
    # attempt is individually rate-limited.
    #
    # @example
    #   bucket = TocDoc::RateLimiter::TokenBucket.new(rate: 5)
    #   builder.use TocDoc::Middleware::RateLimiter, bucket: bucket
    class RateLimiter < Faraday::Middleware
      # @param app [#call] the next middleware in the stack
      # @param bucket [TocDoc::RateLimiter::TokenBucket] the rate-limiting token bucket
      def initialize(app, bucket:)
        super(app)
        @bucket = bucket
      end

      # Acquires a token before forwarding the request downstream.
      #
      # @param env [Faraday::Env] the request environment
      # @return [Faraday::Response]
      def call(env)
        @bucket.acquire
        @app.call(env)
      end
    end
  end
end
