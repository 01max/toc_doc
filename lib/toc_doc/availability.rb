# frozen_string_literal: true

module TocDoc
  # Represents a single availability date entry returned by the Doctolib API.
  #
  # @example
  #   avail = TocDoc::Availability.new('date' => '2026-02-28', 'slots' => ['2026-02-28T10:00:00.000+01:00'])
  #   avail.date   #=> "2026-02-28"
  #   avail.slots  #=> ["2026-02-28T10:00:00.000+01:00"]
  class Availability < Resource
    # @return [String] date in ISO 8601 format (e.g. "2026-02-28")
    def date
      @attrs['date']
    end

    # @return [Array<String>] ISO 8601 datetime strings for each available slot
    def slots
      @attrs['slots'] || []
    end
  end
end
