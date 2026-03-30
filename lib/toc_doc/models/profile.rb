# frozen_string_literal: true

module TocDoc
  # Represents a search profile result (practitioner or organization).
  # Inherits dot-notation attribute access from +TocDoc::Resource+.
  #
  # Use +Profile.build+ to obtain the correctly typed subclass instance.
  #
  # @example
  #   profile = TocDoc::Profile.build('owner_type' => 'Account', 'name' => 'Dr Smith')
  #   profile.class          #=> TocDoc::Profile::Practitioner
  #   profile.practitioner?  #=> true
  #   profile.name           #=> "Dr Smith"
  class Profile < Resource
    # API path template for a full profile page (+sprintf+-style, requires +identifier+).
    # @return [String]
    PATH = '/profiles/%<identifier>s.json'

    main_attrs :id, :partial

    class << self
      # Factory — returns a +Profile::Practitioner+ or +Profile::Organization+.
      #
      # Resolves type via +owner_type+ first (autocomplete context), then falls back
      # to the boolean flags present on profile-page responses.
      #
      # @param attrs [Hash] raw attribute hash from the API response
      # @return [Profile::Practitioner, Profile::Organization]
      # @raise [ArgumentError] if +attrs+ contains an unknown +owner_type+ or the
      #   profile type cannot be determined from the available flags
      #
      # @example Build from an autocomplete result
      #   TocDoc::Profile.build('owner_type' => 'Account', 'name' => 'Dr Smith')
      # @example Build from a full profile response
      #   TocDoc::Profile.build('is_practitioner' => true, 'name' => 'Dr Smith')
      def build(attrs = {})
        attrs = normalize_attrs(attrs)

        return find(attrs['value']) if attrs['force_full_profile']

        build_from_autocomplete(attrs) ||
          build_from_booking_info(attrs) ||
          build_from_full_profile(attrs)
      end

      # Fetches a full profile page by slug or numeric ID.
      #
      # @param identifier [String, Integer] profile slug or numeric ID
      # @return [Profile::Practitioner, Profile::Organization]
      # @raise [ArgumentError] if +identifier+ is +nil+
      #
      # @example
      #   TocDoc::Profile.find('jane-doe-bordeaux')
      #   TocDoc::Profile.find(1542899)
      def find(identifier)
        raise ArgumentError, 'identifier cannot be nil' if identifier.nil?

        data = TocDoc.client.get(format(PATH, identifier: identifier))['data']
        build(profile_attrs(data))
      end

      private

      # Autocomplete results carry an +owner_type+ key that tells us the
      # profile type directly.  When +force_full_profile+ is set, fetches
      # the full profile page instead of building a partial.
      #
      # @param attrs [Hash] normalized attribute hash
      # @return [Profile::Practitioner, Profile::Organization, nil] +nil+ when
      #   +owner_type+ is absent
      # @raise [ArgumentError] if +owner_type+ is present but unrecognised
      def build_from_autocomplete(attrs)
        return unless attrs['owner_type']

        case attrs['owner_type']
        when 'Account'      then Practitioner.new(attrs.merge('partial' => true))
        when 'Organization' then Organization.new(attrs.merge('partial' => true))
        else                     raise ArgumentError, "Unknown owner_type: #{attrs['owner_type']}"
        end
      end

      # Builds a profile from a full profile-page response.
      #
      # @param attrs [Hash] normalized attribute hash from a full profile page
      # @return [Profile::Practitioner, Profile::Organization]
      # @raise [ArgumentError] if neither +is_practitioner+ nor +organization+
      #   flag is present in +attrs+
      def build_from_full_profile(attrs)
        if attrs['is_practitioner']
          Practitioner.new(attrs.merge('partial' => false))
        elsif attrs['organization']
          Organization.new(attrs.merge('partial' => false))
        else
          raise ArgumentError, "Unable to determine profile type from attributes: #{attrs.inspect}"
        end
      end

      # Booking-info profiles carry `organization` (true/false) but lack
      # `is_practitioner`.  Returns nil when the shape doesn't match so the
      # caller can fall through to build_from_full_profile.
      #
      # @param attrs [Hash] normalized attribute hash
      # @return [Profile::Practitioner, Profile::Organization, nil] +nil+ when
      #   the booking-info shape is not matched
      def build_from_booking_info(attrs)
        return unless attrs.key?('organization') && !attrs.key?('is_practitioner')

        return Organization.new(attrs.merge('partial' => true)) if attrs['organization']

        Practitioner.new(attrs.merge('partial' => true))
      end

      # Extracts and coerces profile attributes from the raw API response.
      #
      # @param data [Hash] the +data+ key from the API response body
      # @return [Hash] merged attribute hash with +speciality+ and +places+
      #   coerced into model objects
      def profile_attrs(data)
        data['profile'].merge(
          'speciality' => TocDoc::Speciality.new(data['profile']['speciality'] || {}),
          'places' => Array(data['places']).map { |p| TocDoc::Place.new(p) },
          'legals' => data['legals'],
          'details' => data['details'],
          'fees' => data['fees'],
          'bookable' => data['bookable']
        )
      end
    end

    # Returns all skills across all practices as an array of {TocDoc::Resource}.
    #
    # @return [Array<TocDoc::Resource>]
    #
    # @example
    #   profile.skills  #=> [#<TocDoc::Resource ...>, ...]
    def skills
      hash = self['skills_by_practice'] || {}
      hash.values.flatten.map { |s| TocDoc::Resource.new(s) }
    end

    # Returns skills for a single practice as an array of {TocDoc::Resource}.
    #
    # @param practice_id [Integer, String] the practice ID
    # @return [Array<TocDoc::Resource>]
    #
    # @example
    #   profile.skills_for(123)  #=> [#<TocDoc::Resource ...>, ...]
    def skills_for(practice_id)
      hash = self['skills_by_practice'] || {}
      Array(hash[practice_id.to_s]).map { |s| TocDoc::Resource.new(s) }
    end

    # @return [Boolean] true when this profile is a practitioner
    #
    # @example
    #   profile.practitioner?  #=> true
    def practitioner?
      is_a?(Practitioner)
    end

    # @return [Boolean] true when this profile is an organization
    #
    # @example
    #   profile.organization?  #=> false
    def organization?
      is_a?(Organization)
    end
  end
end

require 'toc_doc/models/profile/practitioner'
require 'toc_doc/models/profile/organization'
