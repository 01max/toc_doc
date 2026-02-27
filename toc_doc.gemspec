# frozen_string_literal: true

require_relative 'lib/toc_doc/version'

Gem::Specification.new do |spec|
  spec.name = 'toc_doc'
  spec.version = TocDoc::VERSION
  spec.authors = ['01max']
  spec.email = ['m.louguet@gmail.com']

  spec.summary = 'A Ruby gem to interact with the (unofficial) Doctolib API.'
  spec.description = "A standalone Ruby gem providing a Faraday-based client
    with modular resource endpoints, configurable defaults, and a clean error hierarchy."
  spec.homepage = 'https://github.com/01max/toc_doc'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/01max/toc_doc'
  spec.metadata['changelog_uri'] = 'https://github.com/01max/toc_doc/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'faraday', '>= 1', '< 3'
  spec.add_runtime_dependency 'faraday-retry', '~> 2.0'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
end
