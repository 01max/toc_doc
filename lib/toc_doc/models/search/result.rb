# frozen_string_literal: true

require 'toc_doc/models/profile'
require 'toc_doc/models/specialty'

module TocDoc
  class Search
    # Envelope returned by {TocDoc::Search.where} when no +type:+ filter is given.
    #
    # Wraps the raw API response and exposes typed collections for profiles and
    # specialities.  Unlike {TocDoc::Availability::Collection} this class does
    # NOT include +Enumerable+ — the dual-type nature of the result does not
    # lend itself to a single iteration interface.
    #
    # @example
    #   result = TocDoc::Search.where(query: 'dentiste')
    #   result.profiles      #=> [#<TocDoc::Profile::Practitioner>, ...]
    #   result.specialities  #=> [#<TocDoc::Specialty>, ...]
    class Result
      # @param data [Hash] raw parsed response body from the autocomplete endpoint
      def initialize(data)
        @data = data
      end

      # All profile results, typed as {TocDoc::Profile::Practitioner} or
      # {TocDoc::Profile::Organization} via {TocDoc::Profile.build}.
      #
      # @return [Array<TocDoc::Profile::Practitioner, TocDoc::Profile::Organization>]
      def profiles
        @profiles ||= Array(@data['profiles']).map do |attrs|
          TocDoc::Profile.build(attrs)
        end
      end

      # All specialty results as {TocDoc::Specialty} instances.
      #
      # @return [Array<TocDoc::Specialty>]
      def specialities
        @specialities ||= Array(@data['specialities']).map do |attrs|
          TocDoc::Specialty.new(attrs)
        end
      end

      # Raw +organization_statuses+ array from the API response (always empty
      # for now — no model exists yet).
      #
      # @return [Array]
      def organization_statuses
        Array(@data['organization_statuses'])
      end

      # Returns a subset of results narrowed to the given type.
      #
      # @param type [String] one of +'profile'+, +'practitioner'+, +'organization'+, +'specialty'+
      # @return [Array<TocDoc::Profile>, Array<TocDoc::Specialty>]
      def filter_by_type(type)
        case type
        when 'profile'      then profiles
        when 'practitioner' then profiles.select(&:practitioner?)
        when 'organization' then profiles.select(&:organization?)
        when 'specialty'    then specialities
        end
      end
    end
  end
end
