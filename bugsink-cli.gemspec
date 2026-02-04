# frozen_string_literal: true

require_relative 'lib/bugsink/version'

Gem::Specification.new do |spec|
  spec.name = 'bugsink-cli'
  spec.version = Bugsink::VERSION
  spec.authors = ['Tomas Kopernik']
  spec.email = ['tomas@kopernik.cz']

  spec.summary = 'CLI tool for interacting with BugSink error tracking API'
  spec.description = 'A command-line interface for the BugSink error tracking service, providing full API access for teams, projects, issues, events, and releases.'
  spec.homepage = 'https://github.com/koperniki/bugsink-cli'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/koperniki/bugsink-cli'
  spec.metadata['changelog_uri'] = 'https://github.com/koperniki/bugsink-cli/blob/main/CHANGELOG.md'

  spec.files = Dir['lib/**/*', 'exe/*', 'README.md', 'CHANGELOG.md', 'LICENSE']
  spec.bindir = 'exe'
  spec.executables = ['bugsink']
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty', '~> 0.22'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
end
