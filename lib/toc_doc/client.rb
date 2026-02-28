# frozen_string_literal: true

require 'toc_doc/configurable'
require 'toc_doc/connection'
require 'toc_doc/uri_utils'
require 'toc_doc/client/availabilities'

module TocDoc
  # The client class for interacting with the TocDoc API.
  class Client
    include TocDoc::Configurable
    include TocDoc::Connection
    include TocDoc::UriUtils

    include TocDoc::Client::Availabilities

    def initialize(options = {})
      reset!
      options.each do |key, value|
        public_send("#{key}=", value) if TocDoc::Configurable.keys.include?(key.to_sym)
      end
    end
  end
end
