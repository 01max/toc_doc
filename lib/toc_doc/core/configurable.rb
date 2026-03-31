# frozen_string_literal: true

require 'toc_doc/core/default'

module TocDoc
  # Mixin providing shared configuration behaviour for both the top-level
  # {TocDoc} module and individual {TocDoc::Client} instances.
  #
  # Include this module to gain attribute accessors for every configurable key,
  # a block-based {#configure} helper, and a {#reset!} method to restore
  # defaults from {TocDoc::Default}.
  #
  # @example Module-level configuration
  #   TocDoc.configure do |config|
  #     config.api_endpoint = 'https://www.doctolib.de'
  #     config.per_page     = 10
  #   end
  #
  # @example Per-client configuration
  #   client = TocDoc::Client.new(api_endpoint: 'https://www.doctolib.it')
  #
  # @see TocDoc::Default
  module Configurable
    # @return [Array<Symbol>] all recognised configuration keys
    VALID_CONFIG_KEYS = %i[
      api_endpoint
      user_agent
      middleware
      connection_options
      default_media_type
      per_page
      connect_timeout
      read_timeout
      logger
    ].freeze

    # @!attribute [rw] api_endpoint
    #   @return [String] the base URL for API requests
    # @!attribute [rw] user_agent
    #   @return [String] the User-Agent header value
    # @!attribute [rw] middleware
    #   @return [Faraday::RackBuilder, nil] custom Faraday middleware stack
    # @!attribute [rw] connection_options
    #   @return [Hash] additional Faraday connection options
    # @!attribute [rw] default_media_type
    #   @return [String] the Accept / Content-Type header value
    # @!attribute [rw] connect_timeout
    #   @return [Integer] TCP connect timeout in seconds
    # @!attribute [rw] read_timeout
    #   @return [Integer] read (response) timeout in seconds
    # @!attribute [rw] logger
    #   @return [Logger, :stdout, nil] logger for HTTP request logging; +nil+ disables logging
    attr_accessor(*VALID_CONFIG_KEYS)

    # Set the number of results per page, clamped to
    # {TocDoc::Default::MAX_PER_PAGE}.
    #
    # Emits a warning on +$stderr+ when +value+ exceeds the hard cap so callers
    # are not silently surprised by the lower effective value.
    #
    # @param value [Integer, #to_i] desired page size
    # @return [Integer] the effective page size after clamping
    def per_page=(value)
      int = value.to_i
      if int > TocDoc::Default::MAX_PER_PAGE
        warn "[TocDoc] per_page #{int} exceeds MAX_PER_PAGE (#{TocDoc::Default::MAX_PER_PAGE}); clamped."
      end
      @per_page = [int, TocDoc::Default::MAX_PER_PAGE].min
    end

    # Returns the list of recognised configurable attribute names.
    #
    # @return [Array<Symbol>]
    def self.keys
      VALID_CONFIG_KEYS
    end

    # Yields +self+ so callers can set options in a block.
    #
    # @yield [config] the object being configured
    # @yieldparam config [TocDoc::Configurable] self
    # @return [self]
    #
    # @example
    #   TocDoc.configure do |config|
    #     config.api_endpoint = 'https://www.doctolib.de'
    #   end
    def configure
      yield self
      self
    end

    # Reset all configuration options to their {TocDoc::Default} values.
    #
    # Calls {TocDoc::Default.reset!} first so that memoized values such as
    # {TocDoc::Default.middleware} are cleared and rebuilt fresh on the next
    # access, preventing stale middleware stacks from being reused.
    #
    # @return [self]
    def reset!
      TocDoc::Default.reset!
      TocDoc::Default.options.each do |key, value|
        public_send("#{key}=", value)
      end
      self
    end

    # Returns a frozen snapshot of the current configuration as a Hash.
    #
    # @return [Hash{Symbol => Object}]
    def options
      Configurable.keys.to_h { |key| [key, public_send(key)] }
    end

    # Compares the given options to the current configuration.
    #
    # Used internally for memoising the {TocDoc.client} instance — a new
    # client is created only when the options have actually changed.
    #
    # @param other_options [Hash{Symbol => Object}] options to compare
    # @return [Boolean] +true+ when both option sets are equal
    def same_options?(other_options)
      candidate =
        if other_options.respond_to?(:to_hash)
          other_options.to_hash.transform_keys!(&:to_sym)
        else
          other_options
        end

      candidate == options
    end

    # @!visibility private
    # When extended (e.g., by the TocDoc module), initialize with defaults.
    def self.extended(base)
      base.reset!
    end
  end
end
