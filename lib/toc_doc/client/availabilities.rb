# frozen_string_literal: true

require 'date'

module TocDoc
  class Client
    # Endpoint module for the Doctolib availabilities API.
    #
    # Included into TocDoc::Client; methods delegate to Connection#get via the
    # enclosing client instance.
    module Availabilities
      # Returns available appointment slots for the given visit motives and
      # agendas.
      #
      # @param visit_motive_ids [Integer, String, Array] one or more visit-motive IDs
      # @param agenda_ids [Integer, String, Array] one or more agenda IDs
      # @param start_date [Date, String] earliest date to search from (default: today)
      # @param limit [Integer] maximum number of results (default: per_page config)
      # @param options [Hash] additional query params forwarded verbatim
      #   (e.g. practice_ids:, telehealth:)
      # @return [Hash] parsed JSON response body
      #
      # @example
      #   client.availabilities(
      #     visit_motive_ids: 7_767_829,
      #     agenda_ids: [1_101_600],
      #     practice_ids: 377_272,
      #     telehealth: false
      #   )
      def availabilities(visit_motive_ids:, agenda_ids:, start_date: Date.today, limit: per_page, **options)
        response = get('/availabilities.json', query: {
                         visit_motive_ids: dashed_ids(visit_motive_ids),
                         agenda_ids: dashed_ids(agenda_ids),
                         start_date: start_date.to_s,
                         limit: limit,
                         **options
                       })
        TocDoc::AvailabilityResponse.new(response)
      end
    end
  end
end
