# frozen_string_literal: true

module TocDoc
  # Represents a speciality returned by the autocomplete endpoint.
  #
  # All fields (+value+, +slug+, +name+) are primitives and are accessed via
  # dot-notation inherited from {TocDoc::Resource}.
  #
  # @example
  #   speciality = TocDoc::Speciality.new('value' => 228, 'slug' => 'homeopathe', 'name' => 'Homéopathe')
  #   speciality.value  #=> 228
  #   speciality.slug   #=> "homeopathe"
  #   speciality.name   #=> "Homéopathe"
  class Speciality < Resource
  end
end
