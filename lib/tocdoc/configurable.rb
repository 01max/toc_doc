# frozen_string_literal: true

require "tocdoc/default"

module Tocdoc
  # Shared configuration behavior for the Tocdoc module and client instances.
  module Configurable
    VALID_CONFIG_KEYS = %i[
      api_endpoint
      user_agent
      middleware
      connection_options
      default_media_type
      per_page
    ].freeze

    # Accessors for all configurable options.
    attr_accessor(*VALID_CONFIG_KEYS)

    # Returns the list of configurable keys.
    def self.keys
      VALID_CONFIG_KEYS
    end

    # Yields self so callers can configure via a block.
    #
    #   Tocdoc.configure do |config|
    #     config.api_endpoint = "https://www.doctolib.de"
    #   end
    def configure
      yield self
      self
    end

    # Reset all configuration options back to Tocdoc::Default values.
    def reset!
      Tocdoc::Default.options.each do |key, value|
        public_send("#{key}=", value)
      end
      self
    end

    # Returns a hash of the current configuration options.
    def options
      Configurable.keys.each_with_object({}) do |key, hash|
        hash[key] = public_send(key)
      end
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

    # When extended (e.g., by the Tocdoc module), initialize with defaults.
    def self.extended(base)
      base.reset!
    end
  end
end
