# frozen_string_literal: true

require 'monitor'

module TocDoc
  module Cache
    # A thread-safe, in-memory response cache with per-entry TTL.
    #
    # Uses lazy expiration: expired entries are evicted on +#read+, not via a
    # background sweep.  The key space is bounded by the number of distinct API
    # URLs, so the overhead is negligible for typical gem usage.
    #
    # Compatible with the ActiveSupport::Cache::Store interface for the methods
    # it implements (+read+, +write+, +delete+, +clear+).
    #
    # @example
    #   store = TocDoc::Cache::MemoryStore.new(default_ttl: 60)
    #   store.write('key', 'value', expires_in: 30)
    #   store.read('key')   #=> 'value'
    class MemoryStore
      # @param default_ttl [Numeric] default TTL in seconds (default: 300)
      def initialize(default_ttl: 300)
        @default_ttl = default_ttl
        @store = {}
        @monitor = Monitor.new
      end

      # Reads the value stored under +key+.
      #
      # Returns +nil+ when the key is absent or has expired (and evicts the
      # entry in the latter case).
      #
      # @param key [String]
      # @return [Object, nil]
      def read(key)
        @monitor.synchronize do
          entry = @store[key]
          return nil unless entry

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) > entry[:expires_at]
            @store.delete(key)
            return nil
          end

          entry[:value]
        end
      end

      # Stores +value+ under +key+ with the given TTL.
      #
      # @param key [String]
      # @param value [Object]
      # @param expires_in [Numeric] TTL in seconds; falls back to +default_ttl+
      # @return [Object] the stored value
      def write(key, value, expires_in: @default_ttl)
        @monitor.synchronize do
          @store[key] = {
            value: value,
            expires_at: Process.clock_gettime(Process::CLOCK_MONOTONIC) + expires_in
          }
          value
        end
      end

      # Deletes the entry for +key+.
      #
      # @param key [String]
      # @return [void]
      def delete(key)
        @monitor.synchronize { @store.delete(key) }
      end

      # Removes all entries from the store.
      #
      # @return [void]
      def clear
        @monitor.synchronize { @store.clear }
      end
    end
  end
end
