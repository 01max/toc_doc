# frozen_string_literal: true

require 'date'
require 'toc_doc/models/availability'

module TocDoc
  class Availability
    # An Enumerable collection of {TocDoc::Availability} instances returned
    # by {TocDoc::Availability.where}.
    #
    # @example Iterate over available slots
    #   collection = TocDoc::Availability.where(visit_motive_ids: 123, agenda_ids: 456)
    #   collection.each { |avail| puts avail.date }
    #
    # @example Access metadata
    #   collection.total      #=> 5
    #   collection.next_slot  #=> "2026-02-28T10:00:00.000+01:00"
    class Collection
      include Enumerable

      attr_reader :path, :query

      # @param data [Hash] parsed first-page response body
      # @param query [Hash] original query params (used to build next-page requests)
      # @param path [String] API path for subsequent requests
      def initialize(data, query: {}, path: '/availabilities.json')
        @data = data.dup
        @query = query
        @path = path
      end

      # Iterates over {TocDoc::Availability} instances that have at least one slot.
      #
      # @yieldparam availability [TocDoc::Availability]
      # @return [Enumerator] if no block given
      def each(&)
        filtered_entries.each(&)
      end

      # The total number of available slots in the collection.
      #
      # @return [Integer]
      def total
        @data['total']
      end

      # The nearest available appointment slot.
      #
      # Returns the +next_slot+ value from the API when present (which only
      # occurs when none of the loaded dates have any slots).  Otherwise
      # returns the first slot of the first date that has one.
      #
      # @return [String, nil] ISO 8601 datetime string, or +nil+ when unavailable
      def next_slot
        return @data['next_slot'] if @data.key?('next_slot')

        Array(@data['availabilities']).each do |entry|
          slots = Array(entry['slots'])
          return slots.first unless slots.empty?
        end

        nil
      end

      # All date entries — including those with no slots — as {TocDoc::Availability}
      # objects.
      #
      # @return [Array<TocDoc::Availability>]
      def raw_availabilities
        Array(@data['availabilities']).map { |entry| TocDoc::Availability.new(entry) }
      end

      # Returns a plain Hash representation of the collection.
      #
      # The +availabilities+ key contains only dates with slots (filtered),
      # serialised back to plain Hashes.
      #
      # @return [Hash{String => Object}]
      def to_h
        @data.merge('availabilities' => filtered_entries.map(&:to_h))
      end

      # Fetches the next window of availabilities (starting the day after the
      # last date in the current collection) and merges them in.
      #
      # @param page_data [Hash] parsed response body to merge into this collection
      # @return [self]
      def merge_page!(page_data)
        @data['availabilities'] = @data.fetch('availabilities', []) + page_data.fetch('availabilities', [])
        @data['total']          = @data.fetch('total', 0) + page_data.fetch('total', 0)
        self
      end

      private

      def filtered_entries
        Array(@data['availabilities'])
          .select { |entry| Array(entry['slots']).any? }
          .map { |entry| TocDoc::Availability.new(entry) }
      end
    end
  end
end
