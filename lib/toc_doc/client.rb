# frozen_string_literal: true

require 'toc_doc/configurable'

module TocDoc
  # The client class for interacting with the TocDoc API.
  class Client
    include TocDoc::Configurable

    def initialize(options = {})
      reset!
      options.each do |key, value|
        public_send("#{key}=", value) if TocDoc::Configurable.keys.include?(key.to_sym)
      end
    end
  end
end
