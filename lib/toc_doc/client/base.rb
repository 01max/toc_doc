# frozen_string_literal: true

module TocDoc
  class Client
    # Shared foundation for all TocDoc clients.
    class Base
      include TocDoc::UriUtils
    end
  end
end
