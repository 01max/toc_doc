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
    # @return [String] raw date string in ISO 8601 format (e.g. "2026-02-28")
    def raw_date
      @attrs['date']
    end

    # @return [Date] parsed date
    def date
      Date.parse(raw_date)
    end

    # @return [Array<String>] raw ISO 8601 datetime strings for each available slot
    def raw_slots
      @attrs['slots'] || []
    end

    # @return [Array<DateTime>] parsed datetime objects for each available slot
    def slots
      raw_slots.map { |s| DateTime.parse(s) }
    end
  end
end
