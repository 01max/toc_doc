# frozen_string_literal: true

require 'toc_doc/models/profile'
require 'toc_doc/models/speciality'

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
    #   result.specialities  #=> [#<TocDoc::Speciality>, ...]
    class Result
      # @param data [Hash] raw parsed response body from the autocomplete endpoint
      def initialize(data)
        @profiles     = build_profiles(data['profiles'])
        @specialities = build_specialities(data['specialities'])
      end

      # All profile results, typed as {TocDoc::Profile::Practitioner} or
      # {TocDoc::Profile::Organization} via {TocDoc::Profile.build}.
      #
      # @return [Array<TocDoc::Profile::Practitioner, TocDoc::Profile::Organization>]
      attr_reader :profiles

      # All speciality results as {TocDoc::Speciality} instances.
      #
      # @return [Array<TocDoc::Speciality>]
      attr_reader :specialities

      # Returns a subset of results narrowed to the given type.
      #
      # @param type [String] one of +'profile'+, +'practitioner'+, +'organization'+, +'speciality'+
      # @return [Array<TocDoc::Profile>, Array<TocDoc::Speciality>]
      def filter_by_type(type)
        case type
        when 'profile'      then profiles
        when 'practitioner' then profiles.select(&:practitioner?)
        when 'organization' then profiles.select(&:organization?)
        when 'speciality'   then specialities
        end
      end

      private

      def build_profiles(raw)
        Array(raw).map { |attrs| TocDoc::Profile.build(attrs) }
      end

      def build_specialities(raw)
        Array(raw).map { |attrs| TocDoc::Speciality.new(attrs) }
      end
    end
  end
end
