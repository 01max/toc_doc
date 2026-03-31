# frozen_string_literal: true

require 'json'
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
    # API path for the slot-selection funnel info endpoint.
    # @return [String]
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
      @specialities ||= Array(@data['specialities']).map do |speciality_attrs|
        Speciality.new(speciality_attrs)
      end
    end

    # All visit motives for this booking context.
    #
    # @return [Array<TocDoc::VisitMotive>]
    def visit_motives
      @visit_motives ||= Array(@data['visit_motives']).map do |visit_motive_attrs|
        VisitMotive.new(visit_motive_attrs)
      end
    end

    # All agendas for this booking context.
    #
    # Visit motives are resolved via a hash index keyed by ID, so lookup is O(1)
    # per motive rather than O(n) per agenda. Unknown visit_motive_ids are
    # silently dropped.
    #
    # @return [Array<TocDoc::Agenda>]
    def agendas
      @agendas ||= begin
        vm_index = visit_motives.to_h { |vm| [vm.id, vm] }

        Array(@data['agendas']).map do |agenda_attrs|
          agenda_visit_motives = Array(agenda_attrs['visit_motive_ids']).filter_map { |id| vm_index[id] }
          Agenda.new(agenda_attrs.merge('visit_motives' => agenda_visit_motives))
        end
      end
    end

    # All practice locations for this booking context.
    #
    # @return [Array<TocDoc::Place>]
    def places
      @places ||= Array(@data['places']).map do |place_attrs|
        Place.new(place_attrs)
      end
    end

    # All practitioners associated with this booking context.
    #
    # Always constructed as {TocDoc::Profile::Practitioner} since the
    # +practitioners+ array in this endpoint exclusively contains practitioners.
    # Marked as partial since the data is a summary, not a full profile page.
    #
    # @return [Array<TocDoc::Profile::Practitioner>]
    def practitioners
      @practitioners ||= Array(@data['practitioners']).map do |practitioner_attrs|
        Profile::Practitioner.new(practitioner_attrs.merge('partial' => true))
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

    # Returns the raw data hash as received from the API.
    #
    # @return [Hash]
    def raw
      @data
    end

    # Returns a hydrated hash with all typed collections serialized to plain
    # Hashes. Unlike {#raw}, nested objects are converted via their own
    # +#to_h+ methods.
    #
    # @return [Hash{String => Object}]
    def to_h
      {
        'profile' => profile.to_h,
        'specialities' => specialities.map(&:to_h),
        'visit_motives' => visit_motives.map(&:to_h),
        'agendas' => agendas.map(&:to_h),
        'places' => places.map(&:to_h),
        'practitioners' => practitioners.map(&:to_h)
      }
    end

    # Serialize the booking info to a JSON string.
    #
    # @param args [Array] forwarded to +Hash#to_json+
    # @return [String]
    def to_json(*)
      to_h.to_json(*)
    end
  end
end
