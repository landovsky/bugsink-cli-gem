# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-04

### Added
- Initial release of bugsink-cli gem
- Complete BugSink API wrapper with support for:
  - Teams (list, get, create, update)
  - Projects (list, get, create, update)
  - Issues (list, get) - read-only
  - Events (list, get, stacktrace) - read-only
  - Releases (list, get, create)
- Configuration management via environment variables and .bugsink dotfile
- Multiple output formats: table, JSON, quiet
- Comprehensive CLI with help system
- HTTParty-based HTTP client with error handling
