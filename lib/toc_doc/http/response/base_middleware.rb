# frozen_string_literal: true

require 'faraday'

module TocDoc
  # @api private
  module Response
    # Abstract base class for TocDoc Faraday response middleware.
    #
    # Subclasses **must** override {#on_complete} to inspect or transform
    # the response environment.
    #
    # @abstract
    class BaseMiddleware < Faraday::Middleware
      # Called by Faraday after the response has been received.
      #
      # @param env [Faraday::Env] the Faraday response environment
      # @return [void]
      # @raise [NotImplementedError] always — subclasses must override
      def on_complete(env)
        raise NotImplementedError, "#{self.class} must implement #on_complete"
      end
    end
  end
end
