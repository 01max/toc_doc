# frozen_string_literal: true

require 'faraday'

module TocDoc
  module Middleware
    # Faraday response middleware that wraps Faraday HTTP errors into
    # TocDoc::Error, keeping Faraday as an internal implementation detail.
    class RaiseError < Faraday::Middleware
      def call(env)
        @app.call(env)
      rescue Faraday::Error => e
        raise TocDoc::Error, e.message
      end
    end
  end
end
