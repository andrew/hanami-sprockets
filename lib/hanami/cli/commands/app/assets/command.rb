# frozen_string_literal: true

require "pathname"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          class Command
            def initialize(out: $stdout)
              @out = out
            end

            def call(app: nil)
              assets = create_assets_instance(app)
              output_dir = default_output_dir(app)

              execute_assets_command(assets, output_dir)
            end

            protected

            attr_reader :out

            def create_assets_instance(app)
              root = app ? app.root : Pathname.pwd
              config = Hanami::Assets::Config.new(digest: true)
              Hanami::Assets.new(config: config, root: root.to_s)
            end

            def default_output_dir(app)
              root = app ? app.root : Pathname.pwd
              root.join("public", "assets").to_s
            end

            def execute_assets_command(assets, output_dir)
              raise NotImplementedError, "Subclasses must implement #execute_assets_command"
            end
          end
        end
      end
    end
  end
end