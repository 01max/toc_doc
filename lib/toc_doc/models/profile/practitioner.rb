# frozen_string_literal: true

module TocDoc
  class Profile
    # A practitioner profile (raw +owner_type: "Account"+).
    class Practitioner < Profile
      main_attrs :name_with_title

      # Returns the practitioner's display name.
      #
      # Prefers +name_with_title+ (e.g. "Dr Jane Doe") when present,
      # falling back to plain +name+.
      #
      # @return [String]
      def to_s
        (respond_to?(:name_with_title) && name_with_title) || name
      end
    end
  end
end
