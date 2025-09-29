# frozen_string_literal: true

require "json"
require "pathname"
require "zeitwerk"
require "sprockets"
require "base64"
require "digest"

module Hanami
  # Assets management for Ruby web applications using Sprockets
  #
  # @since 0.1.0
  class Assets
    # @since 0.1.0
    # @api private
    def self.gem_loader
      @gem_loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path("..", __dir__)
        loader.tag = "hanami-sprockets"
        loader.push_dir(root)
        loader.ignore(
          "#{root}/hanami-sprockets.rb",
          "#{root}/hanami/sprockets/version.rb",
          "#{root}/hanami/sprockets/errors.rb"
        )
        loader.enable_reloading if loader.respond_to?(:enable_reloading)
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/hanami-sprockets.rb")
      end
    end

    gem_loader.setup
    require_relative "sprockets/version"
    require_relative "sprockets/errors"
    require_relative "sprockets/config"
    require_relative "sprockets/base_url"
    require_relative "sprockets/asset"
    require_relative "sprockets/helpers"
    require_relative "sprockets/middleware"

    # Returns the directory (under `public/assets/`) to be used for storing a slice's compiled
    # assets.
    #
    # This is shared logic used by both Hanami (for the assets provider) and Hanami::CLI (for the
    # assets commands).
    #
    # @since 0.1.0
    # @api private
    def self.public_assets_dir(slice)
      return nil if slice.app.eql?(slice)

      slice.slice_name.to_s.split("/").map { |name| "_#{name}" }.join("/")
    end

    # @api private
    # @since 0.1.0
    attr_reader :config

    # @api private
    # @since 0.1.0
    attr_reader :root

    # @api private
    # @since 0.1.0
    attr_reader :environment

    # @api public
    # @since 0.1.0
    def initialize(config:, root:)
      @config = config
      @root = Pathname(root)
      @environment = setup_sprockets_environment
    end

    # Returns the asset at the given path.
    #
    # @return [Hanami::Sprockets::Asset] the asset
    #
    # @raise AssetMissingError if no asset can be found at the path
    #
    # @api public
    # @since 0.1.0
    def [](path)
      # Find the asset using Sprockets
      sprockets_asset = environment.find_asset(path)

      raise AssetMissingError.new(path) unless sprockets_asset

      # Generate the asset path - use digest_path for fingerprinting in production
      asset_path = if config.digest
        "#{config.path_prefix}/#{sprockets_asset.digest_path}"
      else
        "#{config.path_prefix}/#{sprockets_asset.logical_path}"
      end

      # Create our Asset wrapper
      Asset.new(
        path: asset_path,
        base_url: config.base_url,
        sri: calculate_sri(sprockets_asset),
        logical_path: sprockets_asset.logical_path,
        digest_path: sprockets_asset.digest_path,
        content_type: sprockets_asset.content_type,
        source: sprockets_asset.source
      )
    end

    # Returns true if subresource integrity is configured.
    #
    # @return [Boolean]
    #
    # @api public
    # @since 0.1.0
    def subresource_integrity?
      config.subresource_integrity.any?
    end

    # Returns true if the given source path is a cross-origin request.
    #
    # @return [Boolean]
    #
    # @api public
    # @since 0.1.0
    def crossorigin?(source_path)
      config.crossorigin?(source_path)
    end

    # Precompile assets (for production)
    #
    # @api public
    # @since 0.1.0
    def precompile(target_dir = nil, &block)
      target_dir ||= root.join("public", "assets")
      target_dir = Pathname(target_dir)
      target_dir.mkpath

      manifest = ::Sprockets::Manifest.new(environment, target_dir, "manifest.json")

      # Precompile configured assets - compile by explicit names first
      ['app.css', 'app.js'].each do |asset|
        begin
          manifest.compile(asset)
          block&.call(asset) if block
        rescue Sprockets::FileNotFound
          # Asset doesn't exist, skip it
        end
      end

      # Then process configured precompile patterns
      config.precompile.each do |asset|
        begin
          manifest.compile(asset)
          block&.call(asset) if block
        rescue Sprockets::FileNotFound
          # Asset doesn't exist, skip it
        end
      end

      # Write the manifest file
      File.write(File.join(target_dir, "manifest.json"), JSON.pretty_generate(manifest.assets))

      manifest
    end

    # Get all logical paths (useful for debugging)
    #
    # @api public
    # @since 0.1.0
    def logical_paths
      paths = []
      # Walk through all load paths and find assets
      environment.paths.each do |load_path|
        next unless Dir.exist?(load_path)

        Dir.glob("**/*", base: load_path).each do |file|
          full_path = File.join(load_path, file)
          next unless File.file?(full_path)
          next if File.basename(file).start_with?(".")

          # Try to find it as an asset to see if Sprockets can handle it
          begin
            if environment.find_asset(file)
              paths << file
            end
          rescue
            # Skip files that cause errors
          end
        end
      end

      paths.uniq.sort
    end
    # Clear the cache (useful in development)
    #
    # @api public
    # @since 0.1.0
    def clear_cache!
      @environment = setup_sprockets_environment
    end

    private

    def setup_sprockets_environment
      env = ::Sprockets::Environment.new(root.to_s)

      # Set up context class for helpers
      assets_config = config
      env.context_class.class_eval do
        define_method :asset_path do |path, options = {}|
          # Find the asset and return its path
          asset = environment.find_asset(path)
          if asset
            if assets_config.digest
              "#{assets_config.path_prefix}/#{asset.digest_path}"
            else
              "#{assets_config.path_prefix}/#{asset.logical_path}"
            end
          else
            "#{assets_config.path_prefix}/#{path}"
          end
        end

        define_method :asset_url do |path, options = {}|
          asset_path(path, options)
        end
      end

      # Add common Rails-like asset paths
      potential_paths = [
        "app/assets/stylesheets",
        "app/assets/javascripts",
        "app/assets/images",
        "app/assets/fonts",
        "lib/assets/stylesheets",
        "lib/assets/javascripts",
        "lib/assets/images",
        "vendor/assets/stylesheets",
        "vendor/assets/javascripts",
        "vendor/assets/images"
      ]

      potential_paths.each do |path_str|
        full_path = root.join(path_str)
        env.append_path(full_path.to_s) if full_path.exist?
      end

      # Add any additional paths from config
      config.asset_paths.each { |path| env.append_path(path) }

      # Configure processors based on what gems are available
      configure_processors(env)

      env
    end

    def configure_processors(env)
      # Sprockets will auto-detect most processors if the gems are available
      # But we can explicitly configure them here if needed

      # SCSS/Sass support (if sass-rails or sassc-rails is available)
      begin
        require 'sassc'
        # Sprockets will automatically use SassC if available
      rescue LoadError
        # Sass not available, that's fine
      end

      # CoffeeScript support (if coffee-rails is available)
      begin
        require 'coffee_script'
        # Sprockets will automatically use CoffeeScript if available
      rescue LoadError
        # CoffeeScript not available, that's fine
      end

      # ES6+ support via Babel (if babel-transpiler is available)
      begin
        require 'babel/transpiler'
        env.register_transformer 'application/javascript', 'application/javascript', Sprockets::BabelProcessor
      rescue LoadError
        # Babel not available, that's fine
      end
    end

    def calculate_sri(sprockets_asset)
      return nil unless subresource_integrity?

      algorithms = config.subresource_integrity
      sri_values = []

      algorithms.each do |algorithm|
        case algorithm
        when :sha256
          sri_values << "sha256-#{Base64.strict_encode64(Digest::SHA256.digest(sprockets_asset.source))}"
        when :sha384
          sri_values << "sha384-#{Base64.strict_encode64(Digest::SHA384.digest(sprockets_asset.source))}"
        when :sha512
          sri_values << "sha512-#{Base64.strict_encode64(Digest::SHA512.digest(sprockets_asset.source))}"
        end
      end

      sri_values.join(" ")
    end
  end
end