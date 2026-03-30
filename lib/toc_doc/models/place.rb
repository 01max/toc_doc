# frozen_string_literal: true

module TocDoc
  # Represents a practice location returned inside a profile response.
  #
  # All fields are accessible via dot-notation inherited from {TocDoc::Resource}.
  # Nested arrays (+opening_hours+, +stations+) are returned as raw arrays of hashes.
  #
  # @example
  #   place = TocDoc::Place.new(
  #     'id'               => 'practice-125055',
  #     'address'          => '1 Rue Anonyme',
  #     'zipcode'          => '33000',
  #     'city'             => 'Bordeaux',
  #     'full_address'     => '1 Rue Anonyme, 33000 Bordeaux',
  #     'landline_number'  => '05 23 45 67 89',
  #     'latitude'         => 44.8386722,
  #     'longitude'        => -0.5780466,
  #     'elevator'         => true,
  #     'handicap'         => true,
  #     'formal_name'      => 'Centre de santé - Anonyme'
  #   )
  #   place.id               #=> "practice-125055"
  #   place.city             #=> "Bordeaux"
  #   place.full_address     #=> "1 Rue Anonyme, 33000 Bordeaux"
  #   place.landline_number  #=> "05 23 45 67 89"
  #   place.latitude         #=> 44.8386722
  #   place.elevator         #=> true
  class Place < Resource
    # Returns the geographic coordinates of the place.
    #
    # @return [Array(Float, Float)] +[latitude, longitude]+
    #
    # @example
    #   place.coordinates  #=> [44.8386722, -0.5780466]
    def coordinates
      [latitude, longitude]
    end
  end
end
