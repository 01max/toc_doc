# frozen_string_literal: true

module TocDoc
  # A lightweight wrapper providing dot-notation access to response fields.
  # Backed by a Hash, with +method_missing+ for attribute access and +#to_h+ for
  # round-tripping back to a plain Hash.
  #
  # Unlike Sawyer, TocDoc does not use hypermedia relations, so this wrapper
  # intentionally stays minimal.
  #
  # @example
  #   resource = TocDoc::Resource.new('date' => '2026-02-28', 'slots' => [])
  #   resource.date   #=> "2026-02-28"
  #   resource[:date] #=> "2026-02-28"
  #   resource.to_h   #=> { "date" => "2026-02-28", "slots" => [] }
  class Resource
    class << self
      # Normalises a raw attribute hash to string keys, mirroring what
      # {#initialize} does internally. Useful in class-level factory methods
      # that need to inspect attrs before wrapping them in a Resource instance.
      #
      # @param attrs [Hash] raw hash with string or symbol keys
      # @return [Hash{String => Object}]
      def normalize_attrs(attrs)
        attrs.transform_keys(&:to_s)
      end

      # Declares which attribute keys are shown in +#inspect+.
      # When called with arguments, sets the list for this class.
      # When called with no arguments, returns the list (or +nil+ if unset),
      # walking the ancestor chain so subclasses inherit the declaration.
      #
      # Subclasses that never call +main_attrs+ fall back to showing all attrs.
      #
      # @example
      #   main_attrs :id, :name, :slug
      #
      # @param keys [Array<Symbol, String>]
      # @return [Array<String>, nil]
      def main_attrs(*keys)
        if keys.empty?
          ancestor = ancestors.find { |a| a.instance_variable_defined?(:@main_attrs) }
          ancestor&.instance_variable_get(:@main_attrs)
        else
          inherited = superclass.respond_to?(:main_attrs) ? (superclass.main_attrs || []) : []
          @main_attrs = (inherited + keys.map(&:to_s)).uniq
        end
      end
    end

    # @param attrs [Hash] the raw attribute hash (string or symbol keys)
    def initialize(attrs = {})
      @attrs = self.class.normalize_attrs(attrs)
    end

    # Read an attribute by name.
    #
    # @param key [String, Symbol] attribute name
    # @return [Object, nil] the attribute value, or +nil+ if not present
    #
    # @example
    #   resource[:date] #=> "2026-02-28"
    def [](key)
      @attrs[key.to_s]
    end

    # Write an attribute by name.
    #
    # @param key [String, Symbol] attribute name
    # @param value [Object] the value to set
    # @return [Object] the value
    def []=(key, value)
      @attrs[key.to_s] = value
    end

    # Return a plain Hash representation (shallow copy).
    #
    # @return [Hash{String => Object}]
    def to_h
      @attrs.dup
    end

    # Equality comparison.
    #
    # Two {Resource} instances are equal when their attribute hashes match.
    # A {Resource} is also equal to a plain +Hash+ with equivalent keys.
    #
    # @param other [Resource, Hash, Object]
    # @return [Boolean]
    def ==(other)
      case other
      when Resource then @attrs == other.to_h
      when Hash     then @attrs == self.class.normalize_attrs(other)
      else false
      end
    end

    # @!visibility private
    def respond_to_missing?(method_name, include_private = false)
      @attrs.key?(method_name.to_s) || super
    end

    # Provides dot-notation access to response fields.
    #
    # Any method call whose name matches a key in the underlying attribute
    # hash is dispatched here.
    #
    # @param method_name [Symbol] the method name
    # @return [Object] the attribute value
    # @raise [NoMethodError] when the key does not exist
    def method_missing(method_name, *_args)
      key = method_name.to_s
      @attrs.key?(key) ? @attrs[key] : super
    end

    # @!visibility private
    def inspect
      keys  = self.class.main_attrs || @attrs.keys
      pairs = keys.map { |k| "@#{k}=#{@attrs[k.to_s].inspect}" }.join(', ')
      "#<#{self.class} #{pairs}>"
    end
  end
end
