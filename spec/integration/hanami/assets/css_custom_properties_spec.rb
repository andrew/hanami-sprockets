# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "CSS Custom Properties" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:assets_dir) { File.join(temp_dir, "app", "assets") }
  let(:config) { Hanami::Assets::Config.new(digest: false) }
  let(:assets) { Hanami::Assets.new(config: config, root: temp_dir) }

  before do
    # Create asset directories
    FileUtils.mkdir_p(File.join(assets_dir, "stylesheets"))

    # Create test CSS file with empty custom properties (like Bootstrap)
    css_dir = File.join(assets_dir, "stylesheets")

    css_content = <<~CSS
      .test-class {
        --bs-form-select-bg-img: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23343a40' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e");
        --empty-custom-property: ;
        background: var(--bs-form-select-bg-img);
      }
    CSS

    File.write(File.join(css_dir, "custom-properties.css"), css_content)
  end

  after do
    # Clean up
    css_file = File.join(temp_dir, "app/assets/stylesheets/custom-properties.css")
    File.delete(css_file) if File.exist?(css_file)
  end

  it "processes CSS files with empty custom properties without error" do
    expect { assets["custom-properties.css"] }.not_to raise_error

    asset = assets["custom-properties.css"]
    expect(asset.source).to include("--empty-custom-property: ;")
    expect(asset.source).to include("--bs-form-select-bg-img:")
  end

  it "preserves CSS custom properties in the output" do
    asset = assets["custom-properties.css"]

    expect(asset.source).to match(/--bs-form-select-bg-img:\s*url\("data:image\/svg\+xml/)
    expect(asset.source).to include("--empty-custom-property: ;")
    expect(asset.source).to include("background: var(--bs-form-select-bg-img)")
  end
end