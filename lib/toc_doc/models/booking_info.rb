# frozen_string_literal: true

require 'toc_doc/models/profile'
require 'toc_doc/models/speciality'
require 'toc_doc/models/place'
require 'toc_doc/models/visit_motive'
require 'toc_doc/models/agenda'

module TocDoc
  # Envelope returned by the slot-selection funnel info endpoint.
  #
  # Wraps the raw API response and exposes typed collections for the booking
  # context: profile, specialities, visit motives, agendas, places, and
  # practitioners.
  #
  # Unlike {TocDoc::Profile}, this class is NOT a {Resource} subclass — it is
  # a plain envelope class, similar in role to {TocDoc::Search::Result}.
  #
  # @example
  #   info = TocDoc::BookingInfo.find('jane-doe-bordeaux')
  #   info.profile        #=> #<TocDoc::Profile::Practitioner>
  #   info.visit_motives  #=> [#<TocDoc::VisitMotive>, ...]
  #   info.organization?  #=> false
  class BookingInfo
    PATH = '/online_booking/api/slot_selection_funnel/v1/info.json'

    class << self
      # Fetches booking info for a profile slug or numeric ID.
      #
      # @param identifier [String, Integer] profile slug or numeric ID,
      #   forwarded as the +profile_slug+ query parameter
      # @return [BookingInfo]
      # @raise [ArgumentError] if +identifier+ is +nil+
      #
      # @example
      #   TocDoc::BookingInfo.find('jane-doe-bordeaux')
      #   TocDoc::BookingInfo.find(325629)
      def find(identifier)
        raise ArgumentError, 'identifier cannot be nil' if identifier.nil?

        data = TocDoc.client.get(PATH, query: { profile_slug: identifier })['data']
        new(data)
      end
    end

    # @param data [Hash] the +data+ value from the API response body
    def initialize(data)
      @data = data
    end

    # The profile associated with this booking context, typed via
    # {TocDoc::Profile.build}.
    #
    # @return [TocDoc::Profile::Practitioner, TocDoc::Profile::Organization]
    def profile
      @profile ||= Profile.build(@data['profile'])
    end

    # All specialities for this booking context.
    #
    # @return [Array<TocDoc::Speciality>]
    def specialities
      @specialities ||= Array(@data['specialities']).map { |s| Speciality.new(s) }
    end

    # All visit motives for this booking context.
    #
    # @return [Array<TocDoc::VisitMotive>]
    def visit_motives
      @visit_motives ||= Array(@data['visit_motives']).map { |v| VisitMotive.new(v) }
    end

    # All agendas for this booking context.
    #
    # @return [Array<TocDoc::Agenda>]
    def agendas
      @agendas ||= Array(@data['agendas']).map { |a| Agenda.new(a) }
    end

    # All practice locations for this booking context.
    #
    # @return [Array<TocDoc::Place>]
    def places
      @places ||= Array(@data['places']).map { |p| Place.new(p) }
    end

    # All practitioners associated with this booking context.
    #
    # Always constructed as {TocDoc::Profile::Practitioner} since the
    # +practitioners+ array in this endpoint exclusively contains practitioners.
    # Marked as partial since the data is a summary, not a full profile page.
    #
    # @return [Array<TocDoc::Profile::Practitioner>]
    def practitioners
      @practitioners ||= Array(@data['practitioners']).map do |attrs|
        Profile::Practitioner.new(attrs.merge('partial' => true))
      end
    end

    # Returns +true+ when the top-level profile is an organization.
    #
    # Delegates to {TocDoc::Profile#organization?}.
    #
    # @return [Boolean]
    def organization?
      profile.organization?
    end

    # Returns the raw data hash.
    #
    # @return [Hash]
    def to_h
      @data
    end
  end
end
