# frozen_string_literal: true

require 'date'
require 'toc_doc/core/uri_utils'

module TocDoc
  # Represents a single availability date entry returned by the Doctolib API.
  #
  # @example
  #   avail = TocDoc::Availability.new('date' => '2026-02-28', 'slots' => ['2026-02-28T10:00:00.000+01:00'])
  #   avail.date       #=> #<Date: 2026-02-28>
  #   avail.raw_date   #=> "2026-02-28"
  #   avail.slots      #=> [#<DateTime: 2026-02-28T10:00:00.000+01:00>]
  #   avail.raw_slots  #=> ["2026-02-28T10:00:00.000+01:00"]
  class Availability < Resource
    extend TocDoc::UriUtils

    attr_reader :date, :slots

    # API path for the availabilities endpoint.
    # @return [String]
    PATH = '/availabilities.json'

    class << self
      # Fetches availabilities from the API and returns an {Availability::Collection}.
      #
      # When the API response contains a +next_slot+ key — indicating that no
      # date in the current window has available slots — a second request is
      # made automatically from that date before the collection is returned.
      #
      # @param visit_motive_ids [Integer, String, Array<Integer>]
      #   one or more visit-motive IDs (dash-joined for the API)
      # @param agenda_ids [Integer, String, Array<Integer>]
      #   one or more agenda IDs (dash-joined for the API)
      # @param start_date [Date, String]
      #   earliest date to search from (default: +Date.today+)
      # @param limit [Integer]
      #   maximum availability dates per page (default: +TocDoc.per_page+)
      # @param options [Hash]
      #   additional query params forwarded verbatim to the API
      # @return [TocDoc::Availability::Collection]
      #
      # @example
      #   TocDoc::Availability.where(
      #     visit_motive_ids: 7_767_829,
      #     agenda_ids: [1_101_600],
      #     start_date: Date.today
      #   ).each { |avail| puts avail.date }
      def where(visit_motive_ids:, agenda_ids:, start_date: Date.today,
                limit: TocDoc.per_page, **options)
        client = TocDoc.client
        query  = build_query(visit_motive_ids, agenda_ids, start_date, limit, options)
        data   = client.get(PATH, query: query)

        merge_next_page(client, query, data) if data['next_slot']

        Collection.new(data, query: query, path: PATH)
      end

      private

      def merge_next_page(client, query, current_page)
        next_date = Date.parse(current_page['next_slot']).to_s
        next_page = client.get(PATH, query: query.merge(start_date: next_date))
        merge_page_data(current_page, next_page)
      end

      def merge_page_data(current_page, next_page)
        current_page['availabilities'] =
          current_page.fetch('availabilities', []) + next_page.fetch('availabilities', [])
        current_page['total']          = current_page.fetch('total', 0) + next_page.fetch('total', 0)
        current_page.delete('next_slot')
        current_page['next_slot'] = next_page['next_slot'] if next_page.key?('next_slot')
      end

      def build_query(visit_motive_ids, agenda_ids, start_date, limit, extra)
        {
          visit_motive_ids: dashed_ids(visit_motive_ids),
          agenda_ids: dashed_ids(agenda_ids),
          start_date: start_date.to_s,
          limit: [limit.to_i, TocDoc::Default::MAX_PER_PAGE].min,
          **extra
        }
      end
    end

    # @param attrs [Hash] raw attributes from the API response; expected to include
    #   a +date+ key (ISO 8601 date string) and a +slots+ key (Array of ISO 8601 datetime strings)
    def initialize(*attrs)
      super
      raw = build_raw(@attrs)

      @date = Date.parse(raw['date']) if raw['date']
      @slots = raw['slots'].map { |s| DateTime.parse(s) }
    end

    private

    def build_raw(attrs)
      {
        'date' => attrs['date'],
        'slots' => attrs['slots'] || []
      }
    end
  end
end
