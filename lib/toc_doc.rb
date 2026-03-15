# frozen_string_literal: true

require_relative 'toc_doc/core/version'

require 'toc_doc/core/error'
require 'toc_doc/core/configurable'
require 'toc_doc/core/connection'
require 'toc_doc/core/uri_utils'

require 'toc_doc/models'

require 'toc_doc/client'

# The main module for TocDoc — a Ruby client for the Doctolib API.
#
# Configuration can be set at the module level and will be inherited by every
# {TocDoc::Client} instance created via {.client} or {.setup}.
#
# @example Quick start
#   TocDoc.setup do |config|
#     config.api_endpoint = 'https://www.doctolib.de'
#   end
#
#   TocDoc.availabilities(
#     visit_motive_ids: 7_767_829,
#     agenda_ids: 1_101_600,
#     practice_ids: 377_272
#   )
#
# @see TocDoc::Configurable
# @see TocDoc::Client
module TocDoc
  extend Configurable

  class << self
    # Returns a memoized {TocDoc::Client} configured with the current
    # module-level options. A new client is created whenever the options
    # have changed since the last call.
    #
    # @return [TocDoc::Client]
    def client
      if !defined?(@client) || @client.nil? || !@client.respond_to?(:same_options?) || !@client.same_options?(options)
        @client = TocDoc::Client.new(options)
      end
      @client
    end

    # Allows replacing the current client instance.
    #
    # @param value [TocDoc::Client] a pre-configured client instance
    # @return [TocDoc::Client]
    attr_writer :client

    # Configure TocDoc at the module level and return the client.
    #
    # @yield [config] yields self so options can be set in a block
    # @yieldparam config [TocDoc] the module itself (responds to {Configurable} setters)
    # @return [TocDoc::Client] the memoized client, reflecting the new configuration
    #
    # @example
    #   TocDoc.setup do |config|
    #     config.api_endpoint = 'https://www.doctolib.de'
    #   end
    def setup
      yield self if block_given?
      client
    end

    # Returns available appointment slots.
    #
    # Delegates to {TocDoc::Availability.where} — see that method for full
    # parameter documentation.
    #
    # @return [TocDoc::Availability::Collection]
    def availabilities(**)
      TocDoc::Availability.where(**)
    end

    # Queries the autocomplete / search endpoint.
    #
    # Delegates to {TocDoc::Search.where} — see that method for full
    # parameter documentation.
    #
    # @return [TocDoc::Search::Result] when called without +type:+
    # @return [Array<TocDoc::Profile>] when +type:+ is +'profile'+,
    #   +'practitioner'+, or +'organization'+
    # @return [Array<TocDoc::Speciality>] when +type:+ is +'speciality'+
    def search(**)
      TocDoc::Search.where(**)
    end

    # @!visibility private
    def method_missing(method_name, ...)
      if client.respond_to?(method_name)
        client.public_send(method_name, ...)
      else
        super
      end
    end

    # @!visibility private
    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name, include_private) || super
    end
  end
end

# Initialize module-level configuration on load.
TocDoc.reset!
