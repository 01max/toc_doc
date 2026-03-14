# frozen_string_literal: true

require 'toc_doc/models/search/result'

module TocDoc
  # Entry point for the autocomplete / search endpoint.
  #
  # Unlike {TocDoc::Availability}, +Search+ is not itself a resource — it is a
  # plain service class that wraps the API call and returns a typed result.
  #
  # @example Fetch everything
  #   result = TocDoc::Search.where(query: 'dentiste')
  #   result          #=> #<TocDoc::Search::Result>
  #   result.profiles #=> [#<TocDoc::Profile::Practitioner>, ...]
  #
  # @example Filter by type
  #   TocDoc::Search.where(query: 'dentiste', type: 'practitioner')
  #   #=> [#<TocDoc::Profile::Practitioner>, ...]
  class Search
    PATH = '/api/searchbar/autocomplete.json'
    VALID_TYPES = %w[profile practitioner organization specialty].freeze

    class << self
      # Queries the autocomplete endpoint and returns a {Search::Result} or a
      # filtered array.
      #
      # The +type:+ keyword is handled client-side only — it is never forwarded
      # to the API.  The full response is always fetched; narrowing happens after.
      #
      # @param query [String] the search term
      # @param type [String, nil] optional filter; one of +'profile'+,
      #   +'practitioner'+, +'organization'+, +'specialty'+
      # @param options [Hash] additional query params forwarded verbatim to the API
      # @return [Search::Result] when +type:+ is +nil+
      # @return [Array<TocDoc::Profile>] when +type:+ is +'profile'+, +'practitioner'+,
      #   or +'organization'+
      # @return [Array<TocDoc::Specialty>] when +type:+ is +'specialty'+
      # @raise [ArgumentError] if +type:+ is not +nil+ and not in {VALID_TYPES}
      #
      # @example
      #   TocDoc::Search.where(query: 'derma', type: 'specialty')
      #   #=> [#<TocDoc::Specialty name="Dermatologue">, ...]
      def where(query:, type: nil, **options)
        if !type.nil? && !VALID_TYPES.include?(type)
          raise ArgumentError, "Invalid type #{type.inspect}. Must be one of: #{VALID_TYPES.join(', ')}"
        end

        data   = TocDoc.client.get(PATH, query: { search: query, **options })
        result = Result.new(data)

        type.nil? ? result : result.filter_by_type(type)
      end
    end
  end
end
