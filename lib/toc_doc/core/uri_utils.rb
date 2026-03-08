# frozen_string_literal: true

module TocDoc
  # URL building helpers for Doctolib API parameters.
  #
  # Doctolib expects certain ID list parameters to be dash-joined strings
  # rather than standard repeated/bracket array notation. Include this module
  # and call +dashed_ids+ explicitly for each such param:
  #
  #   class TocDoc::Availability
  #     extend TocDoc::UriUtils
  #
  #     def self.where(visit_motive_ids:, agenda_ids:, **opts)
  #       client.get('/availabilities.json', query: {
  #         visit_motive_ids: dashed_ids(visit_motive_ids),
  #         agenda_ids:       dashed_ids(agenda_ids),
  #         **opts
  #       })
  #     end
  #   end
  module UriUtils
    # Joins one or many IDs into the dash-separated format expected by Doctolib.
    #
    # @param ids [Integer, String, Array] one or more IDs
    # @return [String] e.g. "1234-5678-9012"
    def dashed_ids(ids)
      Array(ids).flatten.compact.map(&:to_s).reject(&:empty?).join('-')
    end
  end
end
