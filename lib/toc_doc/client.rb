# frozen_string_literal: true

require 'toc_doc/core/configurable'
require 'toc_doc/core/connection'
require 'toc_doc/core/uri_utils'

module TocDoc
  # The main entry-point for interacting with the Doctolib API.
  #
  # A +Client+ inherits the {TocDoc::Configurable} defaults set at the
  # module level and can override any option per-instance.
  #
  # @example Creating a client with custom options
  #   client = TocDoc::Client.new(
  #     api_endpoint: 'https://www.doctolib.de',
  #     per_page: 5
  #   )
  #
  # @see TocDoc::Configurable
  # @see TocDoc::Connection
  class Client
    include TocDoc::Configurable
    include TocDoc::Connection
    include TocDoc::UriUtils

    # Creates a new client instance.
    #
    # Options are merged on top of the module-level {TocDoc::Default} values.
    # Only keys present in {TocDoc::Configurable.keys} are accepted;
    # unknown keys are silently ignored.
    #
    # @param options [Hash{Symbol => Object}] configuration overrides
    # @option options [String]  :api_endpoint      Base URL for API requests
    # @option options [String]  :user_agent         User-Agent header value
    # @option options [String]  :default_media_type Accept / Content-Type header
    # @option options [Integer] :per_page           Results per page
    # @option options [Faraday::RackBuilder] :middleware Custom Faraday middleware
    # @option options [Hash]    :connection_options Additional Faraday options
    #
    # @example
    #   TocDoc::Client.new(api_endpoint: 'https://www.doctolib.it')
    def initialize(options = {})
      reset!
      options.each do |key, value|
        public_send("#{key}=", value) if TocDoc::Configurable.keys.include?(key.to_sym)
      end
    end
  end
end
