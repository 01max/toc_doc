# frozen_string_literal: true

require 'date'

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
    attr_reader :date, :slots

    # @param attrs [Hash] raw attributes from the API response, expected to include
    def initialize(*attrs)
      super(*attrs)
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
