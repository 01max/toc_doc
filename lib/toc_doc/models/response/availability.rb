# frozen_string_literal: true

module TocDoc
  module Response
    # Wraps the top-level response from the Doctolib availabilities API.
    #
    # @example
    #   response = TocDoc::Response::Availability.new(parsed_json)
    #   response.total          #=> 2
    #   response.next_slot      #=> "2026-02-28T10:00:00.000+01:00"
    #   response.availabilities #=> [#<TocDoc::Availability ...>, ...]
    class Availability < Resource
      # @return [Integer] total number of available slots across all dates
      def total
        @attrs['total']
      end

      # @return [String, nil] ISO 8601 datetime of the nearest available slot.
      #   When the API includes a +next_slot+ key (no slots in the loaded window)
      #   that value is returned directly. Otherwise the first slot of the first
      #   date that has one is returned.
      def next_slot
        return @attrs['next_slot'] if @attrs.key?('next_slot')

        Array(@attrs['availabilities']).each do |entry|
          slots = Array(entry['slots'])
          return slots.first unless slots.empty?
        end

        nil
      end

      # @return [Array<TocDoc::Availability>]
      def availabilities
        @availabilities ||= Array(@attrs['availabilities']).map do |entry|
          TocDoc::Availability.new(entry)
        end
      end

      # Returns a plain Hash, with +availabilities+ expanded back to raw Hashes.
      # @return [Hash]
      def to_h
        super.merge('availabilities' => availabilities.map(&:to_h))
      end
    end
  end
end
