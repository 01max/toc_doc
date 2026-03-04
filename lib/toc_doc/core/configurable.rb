# frozen_string_literal: true

require 'toc_doc/core/default'

module TocDoc
  # Shared configuration behavior for the TocDoc module and client instances.
  module Configurable
    VALID_CONFIG_KEYS = %i[
      api_endpoint
      user_agent
      middleware
      connection_options
      default_media_type
      per_page
      auto_paginate
    ].freeze

    # Accessors for all configurable options.
    attr_accessor(*VALID_CONFIG_KEYS)

    # Hard-limit per_page to {TocDoc::Default::MAX_PER_PAGE}.
    def per_page=(value)
      @per_page = [value.to_i, TocDoc::Default::MAX_PER_PAGE].min
    end

    # Returns the list of configurable keys.
    def self.keys
      VALID_CONFIG_KEYS
    end

    # Yields self so callers can configure via a block.
    #
    #   TocDoc.configure do |config|
    #     config.api_endpoint = "https://www.doctolib.de"
    #   end
    def configure
      yield self
      self
    end

    # Reset all configuration options back to TocDoc::Default values.
    def reset!
      TocDoc::Default.options.each do |key, value|
        public_send("#{key}=", value)
      end
      self
    end

    # Returns a hash of the current configuration options.
    def options
      Configurable.keys.to_h { |key| [key, public_send(key)] }
    end

    # Compares the given options hash to the current options for memoization.
    def same_options?(other_options)
      candidate =
        if other_options.respond_to?(:to_hash)
          other_options.to_hash.transform_keys!(&:to_sym)
        else
          other_options
        end

      candidate == options
    end

    # When extended (e.g., by the TocDoc module), initialize with defaults.
    def self.extended(base)
      base.reset!
    end
  end
end
