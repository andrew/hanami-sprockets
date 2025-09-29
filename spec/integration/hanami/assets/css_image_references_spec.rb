# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "CSS image references" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:assets_dir) { File.join(temp_dir, "app", "assets") }
  let(:config) { Hanami::Assets::Config.new(path_prefix: "/assets") }
  let(:assets) { Hanami::Assets.new(config: config, root: temp_dir) }

  before do
    # Create asset directories
    FileUtils.mkdir_p(File.join(assets_dir, "stylesheets"))
    FileUtils.mkdir_p(File.join(assets_dir, "images"))

    # Create a test image
    File.write(File.join(assets_dir, "images", "logo.png"), "fake-png-data")

    # Create CSS with image references using asset-path helper
    File.write(File.join(assets_dir, "stylesheets", "app.css.erb"), <<~CSS)
      .header {
        background-image: url('<%= asset_path("logo.png") %>');
      }

      .footer {
        background: url('<%= asset_path("logo.png") %>') no-repeat;
      }
    CSS

    # Also test plain CSS with relative paths (should work as-is)
    File.write(File.join(assets_dir, "stylesheets", "simple.css"), <<~CSS)
      .simple {
        background-image: url('../images/logo.png');
      }
    CSS
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  it "processes ERB templates with asset_path helpers" do
    css_asset = assets["app.css"]

    expect(css_asset.source).to include("url('/assets/logo")
    expect(css_asset.source).to include(".png')")
    expect(css_asset.logical_path).to eq("app.css")
  end

  it "handles plain CSS files with relative paths" do
    css_asset = assets["simple.css"]

    expect(css_asset.source).to include("url('../images/logo.png')")
    expect(css_asset.logical_path).to eq("simple.css")
  end

  it "can find the referenced image asset" do
    logo_asset = assets["logo.png"]

    expect(logo_asset).to be_a(Hanami::Assets::Asset)
    expect(logo_asset.logical_path).to eq("logo.png")
  end

  context "with fingerprinting enabled" do
    let(:config) { Hanami::Assets::Config.new(path_prefix: "/assets", digest: true) }

    it "generates fingerprinted URLs in CSS" do
      css_asset = assets["app.css"]

      # Should contain fingerprinted path
      expect(css_asset.source).to match(/url\('\/assets\/logo-[a-f0-9]{64}\.png'\)/)
    end
  end
end