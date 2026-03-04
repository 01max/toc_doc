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
      # The total number of available slots across all dates.
      #
      # @return [Integer]
      #
      # @example
      #   response.total #=> 5
      def total
        @attrs['total']
      end

      # The nearest available appointment slot.
      #
      # When the API includes an explicit +next_slot+ key (common when there
      # are no slots in the loaded date window) that value is returned
      # directly.  Otherwise the first slot of the first date that has one
      # is returned.
      #
      # @return [String, nil] ISO 8601 datetime string, or +nil+ when no
      #   slot is available
      #
      # @example
      #   response.next_slot #=> "2026-02-28T10:00:00.000+01:00"
      def next_slot
        return @attrs['next_slot'] if @attrs.key?('next_slot')

        Array(@attrs['availabilities']).each do |entry|
          slots = Array(entry['slots'])
          return slots.first unless slots.empty?
        end

        nil
      end

      # Dates that have at least one available slot, wrapped as
      # {TocDoc::Availability} objects.
      #
      # @return [Array<TocDoc::Availability>]
      #
      # @example
      #   response.availabilities.each do |avail|
      #     puts "#{avail.date}: #{avail.slots.size} slot(s)"
      #   end
      def availabilities
        @availabilities ||= Array(@attrs['availabilities'])
                            .select { |entry| Array(entry['slots']).any? }
                            .map { |entry| TocDoc::Availability.new(entry) }
      end

      # All availability date entries, including those with no slots.
      #
      # @return [Array<TocDoc::Availability>]
      def raw_availabilities
        @raw_availabilities ||= Array(@attrs['availabilities']).map do |entry|
          TocDoc::Availability.new(entry)
        end
      end

      # Returns a plain Hash representation, with nested +availabilities+
      # expanded back to raw Hashes.
      #
      # @return [Hash{String => Object}]
      def to_h
        super.merge('availabilities' => availabilities.map(&:to_h))
      end
    end
  end
end
