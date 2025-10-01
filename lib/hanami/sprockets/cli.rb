# frozen_string_literal: true

require "optparse"
require "pathname"
require "fileutils"

module Hanami
  class Assets
    class CLI
      class << self
        def start(args)
          new(args).call
        end
      end

      def initialize(args)
        @args = args
        @command = nil
        @options = {}
        @root = Pathname.pwd
      end

      def call
        parse_options

        case @command
        when "compile"
          compile
        when "watch"
          watch
        else
          show_help
        end
      end

      private

      def parse_options
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: hanami-sprockets [COMMAND] [OPTIONS]"
          opts.separator ""
          opts.separator "Commands:"
          opts.separator "  compile    Compile assets for production"
          opts.separator "  watch      Watch assets for changes and recompile"
          opts.separator ""
          opts.separator "Options:"

          opts.on("-r", "--root ROOT", "Application root directory") do |root|
            @options[:root] = root
            @root = Pathname(root)
          end

          opts.on("-o", "--output OUTPUT", "Output directory for compiled assets") do |output|
            @options[:output] = output
          end

          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end

        begin
          parser.parse!(@args)
          @command = @args.shift
        rescue OptionParser::InvalidOption => e
          puts "Error: #{e.message}"
          puts parser
          exit(1)
        end
      end

      def compile
        puts "Compiling assets..."

        output_dir = @options[:output] || @root.join("public", "assets").to_s

        assets = create_assets_instance
        manifest = assets.precompile(output_dir)

        puts "Assets compiled successfully:"
        manifest.assets.each do |logical_path, digest_path|
          puts "  #{logical_path} -> #{digest_path}"
        end

        puts "Output directory: #{output_dir}"
      rescue => e
        puts "Error compiling assets: #{e.message}"
        exit(1)
      end

      def watch
        puts "Starting asset watch mode..."
        puts "Press Ctrl+C to stop"

        require "listen"

        assets = create_assets_instance
        asset_paths = find_asset_paths

        if asset_paths.empty?
          puts "No asset directories found. Looking for:"
          %w[app/assets lib/assets vendor/assets].each do |path|
            puts "  #{@root.join(path)}"
          end
          exit(1)
        end

        puts "Watching directories:"
        asset_paths.each { |path| puts "  #{path}" }

        listener = Listen.to(*asset_paths, only: /\.(css|js|scss|sass|coffee|erb)$/) do |modified, added, removed|
          puts "\nChanges detected:"
          (modified + added + removed).each { |file| puts "  #{file}" }

          begin
            puts "Recompiling assets..."
            output_dir = @options[:output] || @root.join("public", "assets").to_s
            assets.precompile(output_dir)
            puts "Assets recompiled successfully"
          rescue => e
            puts "Error recompiling assets: #{e.message}"
          end
        end

        listener.start

        trap("INT") { listener.stop; exit }

        sleep
      rescue LoadError
        puts "Error: 'listen' gem is required for watch mode."
        puts "Add 'gem \"listen\"' to your Gemfile and run 'bundle install'"
        exit(1)
      rescue => e
        puts "Error in watch mode: #{e.message}"
        exit(1)
      end

      def show_help
        puts "Usage: hanami-sprockets [COMMAND] [OPTIONS]"
        puts ""
        puts "Commands:"
        puts "  compile    Compile assets for production"
        puts "  watch      Watch assets for changes and recompile"
        puts ""
        puts "Options:"
        puts "  -r, --root ROOT      Application root directory"
        puts "  -o, --output OUTPUT  Output directory for compiled assets"
        puts "  -h, --help           Show this help message"
        puts ""
        puts "Examples:"
        puts "  hanami-sprockets compile"
        puts "  hanami-sprockets compile -o public/assets"
        puts "  hanami-sprockets watch"
        puts "  hanami-sprockets watch -r /path/to/app"
      end

      def create_assets_instance
        config = Hanami::Assets::Config.new(digest: true)
        Hanami::Assets.new(config: config, root: @root.to_s)
      end

      def find_asset_paths
        paths = []
        %w[app/assets lib/assets vendor/assets].each do |relative_path|
          path = @root.join(relative_path)
          paths << path.to_s if path.exist?
        end
        paths
      end
    end
  end
end