# frozen_string_literal: true

require_relative 'toc_doc/core/version'

require 'toc_doc/core/error'
require 'toc_doc/core/configurable'
require 'toc_doc/core/connection'
require 'toc_doc/core/uri_utils'

require 'toc_doc/models'

require 'toc_doc/client'

# The main module for TocDoc. This is the namespace for all public classes and modules.
module TocDoc
  extend Configurable

  class << self
    # Returns a memoized client configured with the current options.
    def client
      if !defined?(@client) || @client.nil? || !@client.respond_to?(:same_options?) || !@client.same_options?(options)
        @client = TocDoc::Client.new(options)
      end
      @client
    end

    # Allows replacing the current client instance.
    attr_writer :client

    # Configure TocDoc at the module level and return the client.
    #
    #   TocDoc.setup do |config|
    #     config.api_endpoint = 'https://www.doctolib.de'
    #   end
    def setup
      yield self if block_given?
      client
    end

    def method_missing(method_name, ...)
      if client.respond_to?(method_name)
        client.public_send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name, include_private) || super
    end
  end
end

# Initialize module-level configuration on load.
TocDoc.reset!
