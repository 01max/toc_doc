# frozen_string_literal: true

module TocDoc
  # Base error class for all TocDoc errors. Inherits from StandardError so
  # consumers can rescue TocDoc::Error without any knowledge of Faraday.
  class Error < StandardError; end
end
