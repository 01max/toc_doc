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
      # When the API response contains a +next_slot+ key — indicating that no
      # date in the current window has available slots — a second request is
      # made automatically, starting from the date of that +next_slot+ value.
      # This is transparent to the caller.
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
        data = get('/availabilities.json', query: base_query)

        if data['next_slot']
          next_date = Date.parse(data['next_slot']).to_s
          next_page = get('/availabilities.json', query: base_query.merge(start_date: next_date))
          merge_availability_page(data, next_page)
        end

        TocDoc::Response::Availability.new(data)
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

      # Merges a follow-up page body into the accumulator.
      #
      # The +next_slot+ key from the first page is removed; it is only
      # carried forward if the follow-up page also includes one (which
      # would indicate no slots were found there either).
      #
      # @param acc [Hash] the first-page body (mutated in place)
      # @param latest [Hash] the follow-up page body
      # @return [void]
      def merge_availability_page(acc, latest)
        acc['availabilities'] = (acc['availabilities'] || []) + (latest['availabilities'] || [])
        acc['total']          = (acc['total'] || 0) + (latest['total'] || 0)
        acc.delete('next_slot')
        acc['next_slot'] = latest['next_slot'] if latest.key?('next_slot')
      end
    end
  end
end
