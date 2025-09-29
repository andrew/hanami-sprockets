# frozen_string_literal: true

require "hanami/sprockets/helpers"

RSpec.describe Hanami::Assets::Helpers do
  let(:test_class) do
    Class.new do
      include Hanami::Assets::Helpers

      def initialize(assets)
        @hanami_assets = assets
      end

      # Make html_safe work for testing
      class String
        def html_safe
          self
        end unless method_defined?(:html_safe)
      end

      private

      attr_reader :hanami_assets
    end
  end

  let(:base_url) { Hanami::Assets::BaseUrl.new("https://example.com") }
  let(:config) do
    Hanami::Assets::Config.new(path_prefix: "/assets", base_url: base_url, subresource_integrity: [])
  end
  let(:assets) do
    instance_double(
      Hanami::Assets,
      config: config,
      subresource_integrity?: false,
      crossorigin?: false
    )
  end
  let(:helper) { test_class.new(assets) }

  describe "#stylesheet_tag" do
    let(:css_asset) do
      Hanami::Assets::Asset.new(
        path: "/assets/app-abc123.css",
        base_url: base_url,
        logical_path: "app.css",
        content_type: "text/css"
      )
    end

    it "generates stylesheet link tags for local assets" do
      allow(assets).to receive(:[]).with("app.css").and_return(css_asset)

      result = helper.stylesheet_tag("app")

      expect(result).to include('<link href="https://example.com/assets/app-abc123.css"')
      expect(result).to include('type="text/css"')
      expect(result).to include('rel="stylesheet"')
    end

    it "generates stylesheet link tags for external assets" do
      result = helper.stylesheet_tag("https://cdn.example.com/external.css")

      expect(result).to include('href="https://cdn.example.com/external.css"')
      expect(result).to include('type="text/css"')
      expect(result).to include('rel="stylesheet"')
    end

    it "handles missing assets gracefully" do
      allow(assets).to receive(:[]).with("missing.css").and_raise(Hanami::Assets::AssetMissingError.new("missing.css"))

      result = helper.stylesheet_tag("missing")

      expect(result).to include('href="/assets/missing.css"')
    end

    it "supports multiple sources" do
      allow(assets).to receive(:[]).with("app.css").and_return(css_asset)
      allow(assets).to receive(:[]).with("admin.css").and_return(css_asset)

      result = helper.stylesheet_tag("app", "admin")

      expect(result.scan(/<link/).length).to eq(2)
    end
  end

  describe "#javascript_tag" do
    let(:js_asset) do
      Hanami::Assets::Asset.new(
        path: "/assets/app-abc123.js",
        base_url: base_url,
        logical_path: "app.js",
        content_type: "application/javascript"
      )
    end

    it "generates script tags for local assets" do
      allow(assets).to receive(:[]).with("app.js").and_return(js_asset)

      result = helper.javascript_tag("app")

      expect(result).to include('<script src="https://example.com/assets/app-abc123.js"')
      expect(result).to include('type="text/javascript"')
      expect(result).to include('</script>')
    end

    it "generates script tags for external assets" do
      result = helper.javascript_tag("https://cdn.example.com/external.js")

      expect(result).to include('src="https://cdn.example.com/external.js"')
    end

    it "supports custom attributes" do
      allow(assets).to receive(:[]).with("app.js").and_return(js_asset)

      result = helper.javascript_tag("app", async: true, defer: true)

      expect(result).to include('async')
      expect(result).to include('defer')
    end
  end

  describe "#image_tag" do
    let(:png_asset) do
      Hanami::Assets::Asset.new(
        path: "/assets/logo-abc123.png",
        base_url: base_url,
        logical_path: "logo.png",
        content_type: "image/png"
      )
    end

    it "generates image tags" do
      allow(assets).to receive(:[]).with("logo.png").and_return(png_asset)

      result = helper.image_tag("logo")

      expect(result).to include('<img src="https://example.com/assets/logo-abc123.png"')
    end

    it "supports alt text and other attributes" do
      allow(assets).to receive(:[]).with("logo.png").and_return(png_asset)

      result = helper.image_tag("logo", alt: "Company Logo", class: "header-logo")

      expect(result).to include('alt="Company Logo"')
      expect(result).to include('class="header-logo"')
    end
  end

  describe "#asset_url" do
    let(:css_asset) do
      Hanami::Assets::Asset.new(
        path: "/assets/app-abc123.css",
        base_url: base_url
      )
    end

    it "returns full URLs for assets" do
      allow(assets).to receive(:[]).with("app.css").and_return(css_asset)

      result = helper.asset_url("app.css")

      expect(result).to eq("https://example.com/assets/app-abc123.css")
    end

    it "returns external URLs as-is" do
      result = helper.asset_url("https://cdn.example.com/external.css")

      expect(result).to eq("https://cdn.example.com/external.css")
    end
  end

  describe "#asset_path" do
    let(:css_asset) do
      Hanami::Assets::Asset.new(
        path: "/assets/app-abc123.css",
        base_url: base_url
      )
    end

    it "returns paths for assets" do
      allow(assets).to receive(:[]).with("app.css").and_return(css_asset)

      result = helper.asset_path("app.css")

      expect(result).to eq("/assets/app-abc123.css")
    end
  end

  describe "subresource integrity" do
    let(:config) do
      Hanami::Assets::Config.new(path_prefix: "/assets", base_url: base_url, subresource_integrity: [:sha256])
    end

    let(:css_asset) do
      Hanami::Assets::Asset.new(
        path: "/assets/app-abc123.css",
        base_url: base_url,
        sri: "sha256-abc123def456",
        logical_path: "app.css"
      )
    end

    before do
      allow(assets).to receive(:subresource_integrity?).and_return(true)
      allow(assets).to receive(:crossorigin?).and_return(true)
    end

    it "includes integrity attributes for cross-origin assets" do
      allow(assets).to receive(:[]).with("app.css").and_return(css_asset)

      result = helper.stylesheet_tag("app")

      expect(result).to include('integrity="sha256-abc123def456"')
      expect(result).to include('crossorigin="anonymous"')
    end
  end
end