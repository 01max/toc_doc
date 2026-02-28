# frozen_string_literal: true

require 'faraday'

module TocDoc
  module Response
    # Shared foundation for all TocDoc Faraday response middleware.
    # Subclasses should override #on_complete to inspect or transform responses.
    class BaseMiddleware < Faraday::Middleware
      def on_complete(env)
        raise NotImplementedError, "#{self.class} must implement #on_complete"
      end
    end
  end
end
