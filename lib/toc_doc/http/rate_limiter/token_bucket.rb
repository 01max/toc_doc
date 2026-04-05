# frozen_string_literal: true

module TocDoc
  module RateLimiter
    # A thread-safe token-bucket rate limiter using a monotonic clock.
    #
    # Tokens are refilled at a fixed rate; when the bucket is empty, {#acquire}
    # sleeps until the next token is available.
    #
    # @example Allow 5 requests per second
    #   bucket = TocDoc::RateLimiter::TokenBucket.new(rate: 5)
    #   bucket.acquire  # returns immediately while tokens remain
    #
    # @example 2 requests per 2 seconds
    #   bucket = TocDoc::RateLimiter::TokenBucket.new(rate: 2, interval: 2.0)
    class TokenBucket
      MIN_RATE = 1.0

      # @param rate [Numeric] maximum burst capacity and refill amount per +interval+;
      #   clamped to a minimum of +1+
      # @param interval [Float] refill period in seconds (default: 1.0)
      def initialize(rate:, interval: 1.0)
        raw = rate.to_f
        if raw < MIN_RATE
          warn "[TocDoc] rate_limit #{raw} is below minimum; clamped to #{MIN_RATE}."
          raw = MIN_RATE
        end
        @rate     = raw
        @interval = interval.to_f
        @tokens   = @rate
        @last_refill = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @mutex = Mutex.new
      end

      # Blocks until a token is available, then consumes it.
      #
      # The mutex is released while sleeping so other threads can proceed
      # concurrently.
      #
      # @return [void]
      def acquire
        @mutex.synchronize do
          refill
          while @tokens < 1
            sleep_time = @interval / @rate
            @mutex.sleep(sleep_time)
            refill
          end
          @tokens -= 1
        end
      end

      private

      def refill
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        elapsed = now - @last_refill
        @tokens = [@tokens + ((elapsed / @interval) * @rate), @rate].min
        @last_refill = now
      end
    end
  end
end
