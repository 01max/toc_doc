# frozen_string_literal: true

require 'faraday'

module TocDoc
  module Middleware
    # Faraday middleware that logs the outcome of every HTTP request.
    #
    # Placed between {RaiseError} (outermost) and the retry middleware so that
    # each logical request is logged exactly once — after all retry attempts have
    # been exhausted — rather than once per attempt.
    #
    # Stack order (outermost first):
    #   RaiseError > Logging > retry > JSON parse > adapter
    #
    # Log format:
    #   TocDoc: GET /path.json -> 200 (42ms)          # success  → logger.info
    #   TocDoc: GET /path.json -> error: Msg (42ms)   # failure  → logger.warn
    #
    # When no logger is provided the middleware is a no-op.
    #
    # @example Attach a custom logger
    #   TocDoc.configure { |c| c.logger = Logger.new($stdout) }
    #
    # @example Use the :stdout shorthand
    #   TocDoc.configure { |c| c.logger = :stdout }
    class Logging < Faraday::Middleware
      # @param app [#call] the next middleware in the stack
      # @param logger [Logger, nil] the logger to write to; +nil+ disables logging
      def initialize(app, logger: nil)
        super(app)
        @logger = logger
      end

      # Calls the next middleware, measures elapsed time, and logs the outcome.
      #
      # @param env [Faraday::Env] the Faraday request environment
      # @return [Faraday::Response] the response on success
      # @raise [StandardError] re-raises any exception after logging it
      def call(env)
        start    = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        response = @app.call(env)
        duration = duration_ms(start)
        log_request(env, response.status, duration)
        response
      rescue StandardError => e
        duration = duration_ms(start)
        log_error(env, e, duration)
        raise
      end

      private

      # @param start [Float] monotonic clock time at request start
      # @return [Integer] elapsed time in milliseconds
      def duration_ms(start)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
      end

      # Logs a successful HTTP response at +info+ level.
      #
      # @param env [Faraday::Env] the Faraday request environment
      # @param status [Integer] the HTTP response status code
      # @param duration [Integer] elapsed time in milliseconds
      # @return [void]
      def log_request(env, status, duration)
        return unless @logger

        @logger.info("TocDoc: #{env.method.to_s.upcase} #{env.url.path} -> #{status} (#{duration}ms)")
      end

      # Logs a failed request at +warn+ level.
      #
      # @param env [Faraday::Env] the Faraday request environment
      # @param error [StandardError] the exception that was raised
      # @param duration [Integer] elapsed time in milliseconds
      # @return [void]
      def log_error(env, error, duration)
        return unless @logger

        @logger.warn("TocDoc: #{env.method.to_s.upcase} #{env.url.path} -> error: #{error.message} (#{duration}ms)")
      end
    end
  end
end
