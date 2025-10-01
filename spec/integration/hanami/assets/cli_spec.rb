# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "CLI Integration" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:assets_dir) { File.join(temp_dir, "app", "assets") }
  let(:cli_path) { File.expand_path("../../../../bin/hanami-sprockets", __dir__) }

  before do
    # Create test app structure
    FileUtils.mkdir_p(File.join(assets_dir, "stylesheets"))
    FileUtils.mkdir_p(File.join(assets_dir, "javascripts"))

    # Create test files
    File.write(File.join(assets_dir, "stylesheets", "app.css"), <<~CSS)
      body { background: #fff; }
      .header { color: #333; }
    CSS

    File.write(File.join(assets_dir, "javascripts", "app.js"), <<~JS)
      console.log('Hello from app.js');
      document.addEventListener('DOMContentLoaded', function() {
        console.log('DOM loaded');
      });
    JS
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "compile command" do
    it "compiles assets successfully" do
      output_dir = File.join(temp_dir, "public", "assets")

      result = `cd #{temp_dir} && bundle exec #{cli_path} compile 2>&1`

      expect($?.success?).to be true
      expect(result).to include("Compiling assets...")
      expect(result).to include("Assets compiled successfully:")
      expect(result).to include("app.css")

      # Check output files exist
      expect(Dir.exist?(output_dir)).to be true
      css_files = Dir.glob(File.join(output_dir, "*.css"))
      expect(css_files).not_to be_empty

      # Check manifest exists
      manifest_file = File.join(output_dir, "manifest.json")
      expect(File.exist?(manifest_file)).to be true

      manifest = JSON.parse(File.read(manifest_file))
      expect(manifest).to have_key("app.css")
    end

    it "accepts custom output directory" do
      custom_output = File.join(temp_dir, "dist")

      result = `cd #{temp_dir} && bundle exec #{cli_path} compile -o #{custom_output} 2>&1`

      expect($?.success?).to be true
      expect(result).to include("Output directory: #{custom_output}")
      expect(Dir.exist?(custom_output)).to be true
    end
  end

  describe "help command" do
    it "shows help when no command given" do
      result = `bundle exec #{cli_path} 2>&1`

      expect(result).to include("Usage: hanami-sprockets [COMMAND] [OPTIONS]")
      expect(result).to include("compile")
      expect(result).to include("watch")
    end

    it "shows help with --help flag" do
      result = `bundle exec #{cli_path} --help 2>&1`

      expect(result).to include("Usage: hanami-sprockets [COMMAND] [OPTIONS]")
      expect(result).to include("compile")
      expect(result).to include("watch")
    end
  end
end