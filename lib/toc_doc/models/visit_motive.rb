# frozen_string_literal: true

module TocDoc
  # Represents a visit motive (reason for consultation) returned by the booking
  # info endpoint.
  #
  # The +id+ and +name+ fields are the primary attributes. Additional fields
  # such as +restrictions+ are accessible via dot-notation inherited from
  # {TocDoc::Resource}.
  #
  # @example
  #   motive = TocDoc::VisitMotive.new('id' => 1, 'name' => 'Consultation', 'restrictions' => [])
  #   motive.id    #=> 1
  #   motive.name  #=> "Consultation"
  class VisitMotive < Resource
    main_attrs :id, :name
  end
end
