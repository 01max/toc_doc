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
    # @example Load the next window of results
    #   collection.next_slots.each { |avail| puts avail.date }
    #
    # @example Access metadata
    #   collection.total      #=> 5
    #   collection.next_slot  #=> "2026-02-28T10:00:00.000+01:00"
    class Collection
      include Enumerable

      # @param data [Hash] parsed first-page response body
      # @param client [TocDoc::Client, nil] client used for subsequent fetches
      # @param query [Hash] original query params (used to build next-page requests)
      # @param path [String] API path for subsequent requests
      def initialize(data, client: nil, query: {}, path: '/availabilities.json')
        @data = data.dup
        @client = client
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
      # If the follow-up response itself contains a +next_slot+ key (no slots
      # found in that window either), a second request is made transparently
      # from that date before merging.
      #
      # @return [self]
      def next_slots
        return self unless @client

        avails = @data['availabilities'] || []
        last_date_str = avails.last&.dig('date')
        return self unless last_date_str

        next_date = (Date.parse(last_date_str) + 1).to_s
        follow = @client.get(@path, { query: @query.merge(start_date: next_date) })

        if follow['next_slot']
          slot_date = Date.parse(follow['next_slot']).to_s
          follow2   = @client.get(@path, { query: @query.merge(start_date: slot_date) })
          follow['availabilities'] = (follow['availabilities'] || []) + (follow2['availabilities'] || [])
          follow['total']          = (follow['total'] || 0) + (follow2['total'] || 0)
          follow.delete('next_slot')
          follow['next_slot'] = follow2['next_slot'] if follow2.key?('next_slot')
        end

        @data['availabilities'] = (@data['availabilities'] || []) + (follow['availabilities'] || [])
        @data['total']          = (@data['total'] || 0) + (follow['total'] || 0)

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
