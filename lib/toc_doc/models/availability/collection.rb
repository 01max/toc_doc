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
      # @param client [TocDoc::Client, nil] client used to fetch additional pages
      #   via {#fetch_next_page}; +nil+ disables {#fetch_next_page}
      def initialize(data, query: {}, path: '/availabilities.json', client: nil)
        @data = data.dup
        @query = query
        @path = path
        @client = client
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

      # Returns +true+ when the API has indicated that more results exist beyond
      # the currently loaded pages.
      #
      # @return [Boolean]
      def more?
        !!@data['next_slot']
      end

      # Fetches the next page of availabilities and merges it into this collection.
      #
      # Uses the +next_slot+ date from the API response as the +start_date+ for
      # the follow-up request.
      #
      # @raise [TocDoc::Error] if no client was provided at construction time
      # @raise [StopIteration] if {#more?} is +false+
      # @return [self]
      #
      # @example
      #   collection.fetch_next_page if collection.more?
      def fetch_next_page
        raise TocDoc::Error, 'No client available for pagination' unless @client
        raise StopIteration, 'No more pages available' unless more?

        next_date = Date.parse(@data['next_slot']).to_s
        next_page = @client.get(@path, query: @query.merge(start_date: next_date))
        @data.delete('next_slot')
        @data['next_slot'] = next_page['next_slot'] if next_page.key?('next_slot')
        merge_page!(next_page)
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
        @filtered_entries = nil
        self
      end

      private

      def filtered_entries
        @filtered_entries ||= Array(@data['availabilities'])
                              .select { |entry| Array(entry['slots']).any? }
                              .map { |entry| TocDoc::Availability.new(entry) }
      end
    end
  end
end
