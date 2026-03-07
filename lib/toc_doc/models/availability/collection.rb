# frozen_string_literal: true

require 'date'
require 'toc_doc/models/availability'

module TocDoc
  class Availability
    # An Enumerable collection of {TocDoc::Availability} instances returned
    # by {TocDoc::Availability.where}.
    #
    # The first page of data is held eagerly; when +auto_paginate+ is +true+,
    # remaining pages are fetched lazily — deferred until the first call to
    # {#each}, {#total}, {#raw_availabilities}, or {#to_h}.
    #
    # @example Iterate over available slots
    #   collection = TocDoc::Availability.where(visit_motive_ids: 123, agenda_ids: 456)
    #   collection.each { |avail| puts avail.date }
    #
    # @example Access metadata without iterating
    #   collection.total      #=> 5
    #   collection.next_slot  #=> "2026-02-28T10:00:00.000+01:00"
    class Collection
      include Enumerable

      # @param data [Hash] parsed first-page response body
      # @param client [TocDoc::Client, nil] client used for subsequent page fetches
      # @param query [Hash] original query params (used to build next-page requests)
      # @param path [String] API path for subsequent page requests
      # @param auto_paginate [Boolean] whether to fetch remaining pages on first access
      def initialize(data, client: nil, query: {}, path: '/availabilities.json', auto_paginate: false)
        @data = data.dup
        @client = client
        @query = query
        @path = path
        @all_pages_fetched = !auto_paginate
      end

      # Iterates over {TocDoc::Availability} instances that have at least one slot.
      #
      # Triggers pagination when +auto_paginate+ is enabled.
      #
      # @yieldparam availability [TocDoc::Availability]
      # @return [Enumerator] if no block given
      def each(&)
        fetch_remaining_pages!
        filtered_entries.each(&)
      end

      # The total number of available slots in the collection, reflecting the data fetched so far.
      #
      # @return [Integer]
      def total
        @data['total']
      end

      # The nearest available appointment slot, reflecting the data fetched so far.
      #
      # When the API includes an explicit +next_slot+ key that value is returned
      # directly.  Otherwise the first slot of the first date that has one is
      # returned.
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
      # Triggers pagination when +auto_paginate+ is enabled.
      #
      # @return [Array<TocDoc::Availability>]
      def raw_availabilities
        fetch_remaining_pages!
        Array(@data['availabilities']).map { |entry| TocDoc::Availability.new(entry) }
      end

      # Returns a plain Hash representation of the collection.
      #
      # Triggers pagination when +auto_paginate+ is enabled.
      # The +availabilities+ key contains only dates with slots (filtered),
      # serialised back to plain Hashes.
      #
      # @return [Hash{String => Object}]
      def to_h
        fetch_remaining_pages!
        @data.merge('availabilities' => filtered_entries.map(&:to_h))
      end

      private

      def filtered_entries
        Array(@data['availabilities'])
          .select { |entry| Array(entry['slots']).any? }
          .map { |entry| TocDoc::Availability.new(entry) }
      end

      def fetch_remaining_pages!
        return if @all_pages_fetched

        loop do
          next_opts = next_page_options
          break unless next_opts

          latest = @client.get(@path, next_opts)
          merge_page(latest)
        end

        @all_pages_fetched = true
      end

      def next_page_options
        avails = @data['availabilities'] || []
        last_date_str = avails.last&.dig('date')
        return unless last_date_str && @data['next_slot']

        next_start = (Date.parse(last_date_str) + 1).to_s
        { query: @query.merge(start_date: next_start) }
      end

      def merge_page(latest)
        @data['availabilities'] = (@data['availabilities'] || []) + (latest['availabilities'] || [])
        @data['total']          = (@data['total']          || 0) + (latest['total'] || 0)
        @data['next_slot']      = latest['next_slot']
      end
    end
  end
end
