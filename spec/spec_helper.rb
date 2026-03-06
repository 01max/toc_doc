# frozen_string_literal: true

require 'simplecov'

if ENV['CI']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

SimpleCov.start do
  add_filter '/spec/'
end

require 'bundler/setup'
require 'toc_doc'
require 'webmock/rspec'

SPEC_ROOT = File.expand_path('../spec/', __dir__)

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Helper for loading static fixtures
  def fixture_path
    File.join(SPEC_ROOT, 'fixtures')
  end

  def fixture(file)
    File.read(File.join(fixture_path, file))
  end
end
