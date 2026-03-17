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
    PATH = '/profiles/%<identifier>s.json'

    class << self
      # Factory — returns a +Profile::Practitioner+ or +Profile::Organization+.
      #
      # Resolves type via +owner_type+ first (search context), then falls back
      # to the boolean flags present on profile-page responses.
      #
      # @param attrs [Hash] raw attribute hash from the API response
      # @return [Profile::Practitioner, Profile::Organization]
      def build(attrs = {}, full_profile: false)
        if attrs['owner_type'] || attrs[:owner_type]
          return partial_build(attrs) unless full_profile
          return find(attrs['value'] || attrs[:value])
        end

        if attrs['is_practitioner'] || attrs[:is_practitioner]
          Practitioner.new(attrs)
        elsif attrs['organization'] || attrs[:organization]
          Organization.new(attrs)
        else
          raise ArgumentError, 'unable to determine profile type from attributes'
        end
      end

      def partial_build(attrs = {})
        case attrs['owner_type'] || attrs[:owner_type]
        when 'Account'
          Practitioner.new(attrs)
        when 'Organization'
          Organization.new(attrs)
        else
          Resource.new(attrs)
        end
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

        path = format(PATH, identifier: identifier)
        data = TocDoc.client.get(path)['data']

        attrs = data['profile'].merge(
          'speciality' => TocDoc::Speciality.new(data['profile']['speciality'] || {}),
          'places'     => Array(data['places']).map { |p| TocDoc::Place.new(p) },
          'legals'     => data['legals'],
          'details'    => data['details'],
          'fees'       => data['fees'],
          'bookable'   => data['bookable']
        )

        build(attrs)
      end
    end

    # Returns all skills across all practices as an array of {TocDoc::Resource}.
    #
    # @return [Array<TocDoc::Resource>]
    def skills
      hash = self['skills_by_practice'] || {}
      hash.values.flatten.map { |s| TocDoc::Resource.new(s) }
    end

    # Returns skills for a single practice as an array of {TocDoc::Resource}.
    #
    # @param practice_id [Integer, String] the practice ID
    # @return [Array<TocDoc::Resource>]
    def skills_for(practice_id)
      hash = self['skills_by_practice'] || {}
      Array(hash[practice_id.to_s]).map { |s| TocDoc::Resource.new(s) }
    end

    # @return [Boolean] true when this profile is a practitioner
    def practitioner?
      is_a?(Practitioner)
    end

    # @return [Boolean] true when this profile is an organization
    def organization?
      is_a?(Organization)
    end
  end
end

require 'toc_doc/models/profile/practitioner'
require 'toc_doc/models/profile/organization'
