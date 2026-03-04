# frozen_string_literal: true

module TocDoc
  # Base error class for all TocDoc errors.
  #
  # Inherits from +StandardError+ so consumers can rescue `TocDoc::Error`
  # without any knowledge of Faraday or other internal HTTP details.
  #
  # @example Rescuing TocDoc errors
  #   begin
  #     TocDoc.availabilities(visit_motive_ids: 0, agenda_ids: 0)
  #   rescue TocDoc::Error => e
  #     puts e.message
  #   end
  class Error < StandardError; end
end
