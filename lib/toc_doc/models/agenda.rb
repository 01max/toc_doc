# frozen_string_literal: true

module TocDoc
  # Represents an agenda (calendar) returned by the booking info endpoint.
  #
  # The +id+ and +practice_id+ fields are the primary attributes. Additional
  # fields such as +visit_motive_ids+ and +visit_motive_ids_by_practice_id+ are
  # accessible via dot-notation inherited from {TocDoc::Resource}.
  #
  # @example
  #   agenda = TocDoc::Agenda.new(
  #     'id'          => 42,
  #     'practice_id' => 'practice-125055',
  #     'visit_motive_ids' => [1, 2]
  #   )
  #   agenda.id           #=> 42
  #   agenda.practice_id  #=> "practice-125055"
  class Agenda < Resource
    main_attrs :id, :practice_id
  end
end
