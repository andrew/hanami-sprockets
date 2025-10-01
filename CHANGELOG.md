# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-10-01
### Added
- CLI commands: `hanami-sprockets compile` and `hanami-sprockets watch`
- Hanami CLI integration: `hanami assets compile` and `hanami assets watch`
- Asset watch mode with file monitoring and auto-recompilation

### Fixed
- CSS custom properties test failures

## [0.1.0] - 2025-09-29
### Added
- Initial release
- Full Sprockets integration with Rails-like asset pipeline
- Asset fingerprinting and cache busting
- Development middleware for on-the-fly asset serving
- Template helpers (stylesheet_tag, javascript_tag, image_tag)
- Asset precompilation for production
- Subresource Integrity (SRI) support
- Cross-origin request detection
- Compatible with existing Sprockets ecosystem gems
- No npm/Node.js dependencies required
- Comprehensive test suite
- Hanami-compatible API matching original hanami-assets