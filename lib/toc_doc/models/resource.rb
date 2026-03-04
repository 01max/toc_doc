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
    # @param attrs [Hash] the raw attribute hash (string or symbol keys)
    def initialize(attrs = {})
      @attrs = attrs.transform_keys(&:to_s)
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
      when Hash     then @attrs == other.transform_keys(&:to_s)
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
  end
end
