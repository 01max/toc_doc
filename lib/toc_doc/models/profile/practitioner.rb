# frozen_string_literal: true

module TocDoc
  class Profile
    # A practitioner profile (raw +owner_type: "Account"+).
    class Practitioner < Profile
      main_attrs :name_with_title

      def to_s
        (respond_to?(:name_with_title) && name_with_title) || name
      end
    end
  end
end
