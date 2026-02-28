# frozen_string_literal: true

module TocDoc
  # Wraps the top-level response from the Doctolib availabilities API.
  #
  # @example
  #   response = TocDoc::AvailabilityResponse.new(parsed_json)
  #   response.total          #=> 2
  #   response.next_slot      #=> "2026-02-28T10:00:00.000+01:00"
  #   response.availabilities #=> [#<TocDoc::Availability ...>, ...]
  class AvailabilityResponse < Resource
    # @return [Integer] total number of available slots across all dates
    def total
      @attrs['total']
    end

    # @return [String, nil] ISO 8601 datetime of the nearest available slot
    def next_slot
      @attrs['next_slot']
    end

    # @return [Array<TocDoc::Availability>]
    def availabilities
      @availabilities ||= Array(@attrs['availabilities']).map do |entry|
        Availability.new(entry)
      end
    end

    # Returns a plain Hash, with +availabilities+ expanded back to raw Hashes.
    # @return [Hash]
    def to_h
      super.merge('availabilities' => availabilities.map(&:to_h))
    end
  end
end
