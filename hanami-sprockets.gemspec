# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/sprockets/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami-sprockets"
  spec.version       = Hanami::Assets::VERSION
  spec.authors       = ["Andrew Nesbitt"]
  spec.email         = ["andrewnez@gmail.com"]
  spec.summary       = "Sprockets-based assets management for Hanami"
  spec.description   = "Alternative to hanami-assets that uses Sprockets for asset compilation and management, compatible with existing Sprockets gems"
  spec.homepage      = "https://github.com/andrew/hanami-sprockets"
  spec.license       = "MIT"

  spec.files         = `git ls-files -- lib/* bin/* CHANGELOG.md LICENSE.md README.md hanami-sprockets.gemspec`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "sprockets", "~> 4.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_dependency "base64", "~> 0.1"

  spec.add_development_dependency "bundler", ">= 1.6", "< 3"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rack", "~> 2.2"
  spec.add_development_dependency "rack-test", "~> 1.1"
  spec.add_development_dependency "dry-configurable", "~> 1.1"
  spec.add_development_dependency "dry-inflector", "~> 1.0"
end