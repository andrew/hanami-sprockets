# frozen_string_literal: true

require "hanami/sprockets/asset"
require "hanami/sprockets/base_url"

RSpec.describe Hanami::Assets::Asset do
  let(:base_url) { Hanami::Assets::BaseUrl.new("https://example.com") }
  let(:asset) do
    described_class.new(
      path: "/assets/app-abc123.js",
      base_url: base_url,
      sri: "sha256-abc123def456"
    )
  end

  describe "#path" do
    it "returns the asset path" do
      expect(asset.path).to eq("/assets/app-abc123.js")
    end
  end

  describe "#sri" do
    it "returns the subresource integrity value" do
      expect(asset.sri).to eq("sha256-abc123def456")
    end
  end

  describe "#subresource_integrity_value" do
    it "returns the same as sri" do
      expect(asset.subresource_integrity_value).to eq(asset.sri)
    end
  end

  describe "#url" do
    it "returns the full URL by joining base_url and path" do
      expect(asset.url).to eq("https://example.com/assets/app-abc123.js")
    end
  end

  describe "#to_s" do
    it "returns the same as url" do
      expect(asset.to_s).to eq(asset.url)
    end
  end
end