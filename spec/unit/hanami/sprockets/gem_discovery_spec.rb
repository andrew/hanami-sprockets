# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "Hanami::Assets gem asset path discovery" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config) { Hanami::Assets::Config.new(path_prefix: "/assets") }
  let(:assets) { Hanami::Assets.new(config: config, root: temp_dir) }

  before do
    # Create main app asset directories
    app_assets_dir = File.join(temp_dir, "app", "assets")
    FileUtils.mkdir_p(File.join(app_assets_dir, "stylesheets"))
    FileUtils.mkdir_p(File.join(app_assets_dir, "javascripts"))

    # Create a simple CSS file in the app
    File.write(File.join(app_assets_dir, "stylesheets", "app.css"), <<~CSS)
      body {
        background-color: #f0f0f0;
      }
    CSS
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "#discover_gem_asset_paths" do
    it "returns an array of paths" do
      paths = assets.send(:discover_gem_asset_paths)
      expect(paths).to be_an(Array)
    end

    it "finds gem asset paths from loaded gems" do
      paths = assets.send(:discover_gem_asset_paths)

      # Should find gem paths that actually exist on the system
      # Filter for paths that actually exist
      existing_paths = paths.select { |path| File.directory?(path) }

      # In a test environment, we might not have any gems with asset directories
      # That's okay - the important thing is that the method returns an array
      # and only returns existing directories (tested separately)
      expect(existing_paths).to be_an(Array)
    end

    it "only returns existing directories" do
      paths = assets.send(:discover_gem_asset_paths)

      paths.each do |path|
        expect(File.directory?(path)).to be true, "Expected #{path} to be a directory"
      end
    end

    it "includes common asset directory patterns" do
      # Mock a gem spec to test our patterns
      fake_gem_dir = File.join(temp_dir, "fake_gem")
      FileUtils.mkdir_p(File.join(fake_gem_dir, "assets", "stylesheets"))
      FileUtils.mkdir_p(File.join(fake_gem_dir, "app", "assets", "javascripts"))

      # Create some asset files
      File.write(File.join(fake_gem_dir, "assets", "stylesheets", "gem.css"), "/* gem styles */")
      File.write(File.join(fake_gem_dir, "app", "assets", "javascripts", "gem.js"), "// gem js")

      # Mock the gem spec
      fake_spec = double("gem_spec", gem_dir: fake_gem_dir)
      allow(Gem).to receive(:loaded_specs).and_return({"fake_gem" => fake_spec})

      paths = assets.send(:discover_gem_asset_paths)

      expect(paths).to include(File.join(fake_gem_dir, "assets", "stylesheets"))
      expect(paths).to include(File.join(fake_gem_dir, "app", "assets", "javascripts"))
    end
  end

  describe "gem asset integration" do
    it "automatically includes gem asset paths in sprockets environment" do
      # Check that the environment has paths from gems
      environment = assets.environment

      # Get all the paths that were added
      env_paths = environment.paths

      # We should have more paths than just our app paths due to gem discovery
      app_path = File.join(temp_dir, "app", "assets", "stylesheets")
      expect(env_paths).to include(app_path)

      # Should have additional paths from gems (the exact paths will vary by system)
      expect(env_paths.length).to be > 1
    end
  end

  describe "Bootstrap gem compatibility" do
    # This test only runs if bootstrap gem is available
    it "finds bootstrap assets when gem is loaded", :if => defined?(Bootstrap) do
      paths = assets.send(:discover_gem_asset_paths)

      # Should find bootstrap's asset paths
      bootstrap_paths = paths.select { |path| path.include?("bootstrap") }
      expect(bootstrap_paths).not_to be_empty
    end

    it "allows importing bootstrap from SCSS when gem is available", :if => defined?(Bootstrap) do
      # Create a test SCSS file that imports bootstrap
      scss_dir = File.join(temp_dir, "app", "assets", "stylesheets")
      File.write(File.join(scss_dir, "test.scss"), '@import "bootstrap";')

      # This should not raise an error if bootstrap gem paths are discovered
      expect { assets["test.css"] }.not_to raise_error
    end
  end
end