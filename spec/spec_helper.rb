# frozen_string_literal: true

require 'bundler/setup'
require 'tocdoc'
require 'webmock/rspec'
require 'vcr'

SPEC_ROOT = File.expand_path('..', __dir__)

VCR.configure do |config|
  config.cassette_library_dir = File.join(SPEC_ROOT, 'fixtures', 'vcr_cassettes')
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Allow localhost connections (for debugging) and optionally other hosts.
  config.ignore_hosts '127.0.0.1', 'localhost'
end

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Automatically tag examples with VCR metadata via :vcr tag
  config.around(:each, :vcr) do |example|
    name = example.full_description.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/(^_|_$)/, '')
    VCR.use_cassette(name, record: :once, &example)
  end

  # Helper for loading static fixtures
  def fixture_path
    File.join(SPEC_ROOT, 'fixtures')
  end

  def fixture(file)
    File.read(File.join(fixture_path, file))
  end
end
