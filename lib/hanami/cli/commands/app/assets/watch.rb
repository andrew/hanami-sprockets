# frozen_string_literal: true

require_relative "command"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          class Watch < Command
            def execute_assets_command(assets, output_dir)
              out.puts "Starting Sprockets asset watch mode..."
              out.puts "Press Ctrl+C to stop"

              require "listen"

              asset_paths = find_asset_paths(assets)

              if asset_paths.empty?
                out.puts "No asset directories found. Looking for:"
                %w[app/assets lib/assets vendor/assets].each do |path|
                  out.puts "  #{path}"
                end
                return
              end

              out.puts "Watching directories:"
              asset_paths.each { |path| out.puts "  #{path}" }

              listener = Listen.to(*asset_paths, only: /\.(css|js|scss|sass|coffee|erb)$/) do |modified, added, removed|
                out.puts "\nChanges detected:"
                (modified + added + removed).each { |file| out.puts "  #{file}" }

                begin
                  out.puts "Recompiling assets..."
                  assets.precompile(output_dir)
                  out.puts "Assets recompiled successfully"
                rescue => e
                  out.puts "Error recompiling assets: #{e.message}"
                end
              end

              listener.start

              trap("INT") { listener.stop; exit }

              sleep
            rescue LoadError
              out.puts "Error: 'listen' gem is required for watch mode."
              out.puts "Add 'gem \"listen\"' to your Gemfile and run 'bundle install'"
              raise
            rescue => e
              out.puts "Error in watch mode: #{e.message}"
              raise
            end

            private

            def find_asset_paths(assets)
              root = Pathname(assets.root)
              paths = []
              %w[app/assets lib/assets vendor/assets].each do |relative_path|
                path = root.join(relative_path)
                paths << path.to_s if path.exist?
              end
              paths
            end
          end
        end
      end
    end
  end
end