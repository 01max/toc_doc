# frozen_string_literal: true

module TocDoc
  # Represents a specialty returned by the autocomplete endpoint.
  #
  # All fields (+value+, +slug+, +name+) are primitives and are accessed via
  # dot-notation inherited from {TocDoc::Resource}.
  #
  # @example
  #   specialty = TocDoc::Specialty.new('value' => 228, 'slug' => 'homeopathe', 'name' => 'Homéopathe')
  #   specialty.value  #=> 228
  #   specialty.slug   #=> "homeopathe"
  #   specialty.name   #=> "Homéopathe"
  class Specialty < Resource
  end
end
