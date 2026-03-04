# frozen_string_literal: true

require 'faraday'

module TocDoc
  # @api private
  module Middleware
    # Faraday middleware that translates Faraday HTTP errors into
    # {TocDoc::Error}, keeping Faraday as an internal implementation detail.
    #
    # Registered in the default middleware stack built by {TocDoc::Default}.
    #
    # @see TocDoc::Error
    class RaiseError < Faraday::Middleware
      # Executes the request and re-raises any +Faraday::Error+ as a
      # {TocDoc::Error}.
      #
      # @param env [Faraday::Env] the Faraday request environment
      # @return [Faraday::Env] the response environment on success
      # @raise [TocDoc::Error] when Faraday raises an HTTP error
      def call(env)
        @app.call(env)
      rescue Faraday::Error => e
        raise TocDoc::Error, e.message
      end
    end
  end
end
