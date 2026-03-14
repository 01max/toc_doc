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
    # Factory — returns a +Profile::Practitioner+ or +Profile::Organization+
    # depending on the +owner_type+ field of the raw attribute hash.
    #
    # @param attrs [Hash] raw attribute hash from the API response
    # @return [Profile::Practitioner, Profile::Organization]
    def self.build(attrs = {})
      case attrs['owner_type'] || attrs[:owner_type]
      when 'Account'
        Practitioner.new(attrs)
      else
        Organization.new(attrs)
      end
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
