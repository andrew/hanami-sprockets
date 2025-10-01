# frozen_string_literal: true

require_relative "command"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          class Compile < Command
            def execute_assets_command(assets, output_dir)
              out.puts "Compiling assets using Sprockets..."

              manifest = assets.precompile(output_dir)

              out.puts "Assets compiled successfully:"
              manifest.assets.each do |logical_path, digest_path|
                out.puts "  #{logical_path} -> #{digest_path}"
              end

              out.puts "Output directory: #{output_dir}"
            rescue => e
              out.puts "Error compiling assets: #{e.message}"
              raise
            end
          end
        end
      end
    end
  end
end