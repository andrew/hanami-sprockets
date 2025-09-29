# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "Sprockets integration" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:assets_dir) { File.join(temp_dir, "app", "assets") }
  let(:config) { Hanami::Assets::Config.new(path_prefix: "/assets") }
  let(:assets) { Hanami::Assets.new(config: config, root: temp_dir) }

  before do
    # Create asset directories
    FileUtils.mkdir_p(File.join(assets_dir, "stylesheets"))
    FileUtils.mkdir_p(File.join(assets_dir, "javascripts"))
    FileUtils.mkdir_p(File.join(assets_dir, "images"))

    # Create a simple CSS file
    File.write(File.join(assets_dir, "stylesheets", "app.css"), <<~CSS)
      body {
        background-color: #f0f0f0;
        font-family: Arial, sans-serif;
      }
    CSS

    # Create a simple JS file
    File.write(File.join(assets_dir, "javascripts", "app.js"), <<~JS)
      console.log('Hello from Hanami Sprockets!');

      function initializeApp() {
        document.addEventListener('DOMContentLoaded', function() {
          console.log('App initialized');
        });
      }

      initializeApp();
    JS

    # Create a simple image placeholder
    File.write(File.join(assets_dir, "images", "logo.png"), "fake-png-data")
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "#[]" do
    it "finds and returns CSS assets" do
      asset = assets["app.css"]

      expect(asset).to be_a(Hanami::Assets::Asset)
      expect(asset.logical_path).to eq("app.css")
      expect(asset.content_type).to eq("text/css")
      expect(asset.source).to include("background-color: #f0f0f0")
    end

    it "finds and returns JS assets" do
      asset = assets["app.js"]

      expect(asset).to be_a(Hanami::Assets::Asset)
      expect(asset.logical_path).to eq("app.js")
      expect(asset.content_type).to eq("application/javascript")
      expect(asset.source).to include("Hello from Hanami Sprockets!")
    end

    it "raises AssetMissingError for non-existent assets" do
      expect { assets["nonexistent.css"] }
        .to raise_error(Hanami::Assets::AssetMissingError, /nonexistent.css/)
    end
  end

  describe "fingerprinting" do
    context "when digest is enabled" do
      let(:config) { Hanami::Assets::Config.new(path_prefix: "/assets", digest: true) }

      it "returns fingerprinted paths" do
        asset = assets["app.css"]
        expect(asset.path).to match(%r{/assets/app-[a-f0-9]{64}\.css})
      end
    end

    context "when digest is disabled" do
      let(:config) { Hanami::Assets::Config.new(path_prefix: "/assets", digest: false) }

      it "returns non-fingerprinted paths" do
        asset = assets["app.css"]
        expect(asset.path).to eq("/assets/app.css")
      end
    end
  end

  describe "#precompile" do
    let(:output_dir) { File.join(temp_dir, "public", "assets") }

    it "precompiles configured assets" do
      assets.precompile(output_dir)

      expect(File.exist?(output_dir)).to be true

      # List all files for debugging
      all_files = Dir.glob(File.join(output_dir, "**", "*")).select { |f| File.file?(f) }

      # The manifest file might be named differently
      manifest_files = all_files.select { |f| f.include?("manifest") || f.end_with?(".json") }

      expect(manifest_files).not_to be_empty, "Expected to find manifest files, but found: #{all_files}"

      # Check that assets were compiled
      css_files = all_files.select { |f| f.end_with?(".css") }
      js_files = all_files.select { |f| f.end_with?(".js") }

      expect(css_files).not_to be_empty
      expect(js_files).not_to be_empty
    end
  end

  describe "#logical_paths" do
    it "returns all available logical paths" do
      paths = assets.logical_paths

      expect(paths).to include("app.css")
      expect(paths).to include("app.js")
      expect(paths).to include("logo.png")
    end
  end

  describe "subresource integrity" do
    let(:config) do
      Hanami::Assets::Config.new(
        path_prefix: "/assets",
        subresource_integrity: [:sha256]
      )
    end

    it "calculates SRI for assets" do
      asset = assets["app.css"]

      expect(asset.sri).to start_with("sha256-")
      expect(asset.subresource_integrity_value).to eq(asset.sri)
    end
  end

  describe "#crossorigin?" do
    let(:config) do
      Hanami::Assets::Config.new(
        path_prefix: "/assets",
        base_url: "https://cdn.example.com"
      )
    end

    it "returns true for cross-origin requests" do
      expect(assets.crossorigin?("https://other-cdn.com/asset.js")).to be true
    end

    it "returns false for same-origin requests" do
      expect(assets.crossorigin?("https://cdn.example.com/asset.js")).to be false
    end
  end
end