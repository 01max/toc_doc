# frozen_string_literal: true

require 'date'

module TocDoc
  class Client
    # Endpoint module for the Doctolib availabilities API.
    #
    # Included into {TocDoc::Client}; methods delegate to
    # {TocDoc::Connection#get} via the enclosing client instance.
    #
    # @see https://www.doctolib.fr/availabilities.json Doctolib availability endpoint
    module Availabilities
      # Returns available appointment slots for the given visit motives and
      # agendas.
      #
      # When +auto_paginate+ is enabled, all pages of results are
      # fetched and merged automatically.
      #
      # @param visit_motive_ids [Integer, String, Array<Integer>]
      #   one or more visit-motive IDs (dash-joined for the API)
      # @param agenda_ids [Integer, String, Array<Integer>]
      #   one or more agenda IDs (dash-joined for the API)
      # @param start_date [Date, String]
      #   earliest date to search from (default: +Date.today+)
      # @param limit [Integer]
      #   maximum number of availability dates per page
      #   (default: +per_page+ config)
      # @param options [Hash]
      #   additional query params forwarded verbatim to the API
      #   (e.g. +practice_ids:+, +telehealth:+)
      # @return [TocDoc::Response::Availability] structured response object
      #
      # @example Fetch availabilities for a single practitioner
      #   client.availabilities(
      #     visit_motive_ids: 7_767_829,
      #     agenda_ids: [1_101_600],
      #     practice_ids: 377_272,
      #     telehealth: false
      #   )
      #
      # @example Via the module-level shortcut
      #   TocDoc.availabilities(visit_motive_ids: 123, agenda_ids: 456)
      def availabilities(visit_motive_ids:, agenda_ids:, start_date: Date.today, limit: per_page, **options)
        base_query = build_availability_query(visit_motive_ids, agenda_ids, start_date, limit, options)

        response = paginate('/availabilities.json', query: base_query) do |acc, last_resp|
          paginate_availability_page(acc, last_resp, base_query)
        end

        TocDoc::Response::Availability.new(response)
      end

      private

      # Builds the query hash sent to the availabilities endpoint.
      #
      # @param visit_motive_ids [Integer, String, Array] raw motive IDs
      # @param agenda_ids [Integer, String, Array] raw agenda IDs
      # @param start_date [Date, String] earliest search date
      # @param limit [Integer] page size
      # @param extra [Hash] additional query params
      # @return [Hash{Symbol => Object}] ready-to-send query hash
      def build_availability_query(visit_motive_ids, agenda_ids, start_date, limit, extra)
        {
          visit_motive_ids: dashed_ids(visit_motive_ids),
          agenda_ids: dashed_ids(agenda_ids),
          start_date: start_date.to_s,
          limit: [limit.to_i, TocDoc::Default::MAX_PER_PAGE].min,
          **extra
        }
      end

      # Merges the latest page body into the accumulator and returns options
      # for the next page, or +nil+ to halt pagination.
      #
      # On the first yield +acc+ *is* the first-page body (identical object),
      # so the merge step is skipped.
      #
      # @param acc [Hash] growing accumulator
      # @param last_resp [Faraday::Response] the most-recent raw response
      # @param base_query [Hash] the original query hash
      # @return [Hash, nil] options for the next page, or +nil+ to stop
      def paginate_availability_page(acc, last_resp, base_query)
        latest = last_resp.body

        merge_availability_page(acc, latest) unless acc.equal?(latest)
        availability_next_page_options(latest, base_query)
      end

      # Merges a new page body into the running accumulator.
      #
      # @param acc [Hash] the accumulator hash
      # @param latest [Hash] the most-recent page body
      # @return [void]
      def merge_availability_page(acc, latest)
        acc['availabilities'] = (acc['availabilities'] || []) + (latest['availabilities'] || [])
        acc['total']          = (acc['total'] || 0) + (latest['total'] || 0)
        acc['next_slot']      = latest['next_slot']
      end

      # Determines the options for the next page of availabilities, or +nil+
      # if pagination should stop.
      #
      # @param latest [Hash] the most-recent page body
      # @param base_query [Hash] the original query hash
      # @return [Hash, nil] next-page options, or +nil+ to halt
      def availability_next_page_options(latest, base_query)
        avails        = latest['availabilities'] || []
        last_date_str = avails.last&.dig('date')
        return unless last_date_str && latest['next_slot']

        next_start = (Date.parse(last_date_str) + 1).to_s
        { query: base_query.merge(start_date: next_start) }
      end
    end
  end
end
