# frozen_string_literal: true

require "hanami/sprockets/middleware"
require "rack/test"

RSpec.describe Hanami::Assets::Middleware do
  include Rack::Test::Methods

  let(:base_rack_app) do
    lambda { |env| [200, { 'Content-Type' => 'text/html' }, ['Hello World']] }
  end

  let(:config) do
    Hanami::Assets::Config.new(path_prefix: "/assets")
  end

  let(:assets) do
    instance_double(
      Hanami::Assets,
      config: config,
      environment: sprockets_env
    )
  end

  let(:sprockets_env) { instance_double(Sprockets::Environment) }
  let(:middleware) { described_class.new(base_rack_app, assets) }

  def app
    middleware
  end

  describe "#call" do
    context "for non-asset requests" do
      it "passes through to the app" do
        get "/"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("Hello World")
      end
    end

    context "for asset requests" do
      let(:sprockets_asset) do
        instance_double(
          Sprockets::Asset,
          content_type: "text/css",
          source: "body { color: red; }",
          bytesize: 20,
          etag: "abc123"
        )
      end

      it "serves existing assets" do
        allow(sprockets_env).to receive(:find_asset).with("app.css").and_return(sprockets_asset)

        get "/assets/app.css"

        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("text/css")
        expect(last_response.body).to eq("body { color: red; }")
      end

      it "handles fingerprinted assets" do
        allow(sprockets_env).to receive(:find_asset).with("app-abc123def456.css").and_return(nil)
        allow(sprockets_env).to receive(:find_asset).with("app.css").and_return(sprockets_asset)

        get "/assets/app-abc123def456.css"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("body { color: red; }")
      end

      it "returns 404 for missing assets" do
        allow(sprockets_env).to receive(:find_asset).with("missing.css").and_return(nil)

        get "/assets/missing.css"

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq("Asset not found")
      end

      it "returns 500 for asset errors" do
        allow(sprockets_env).to receive(:find_asset).with("app.css").and_raise(StandardError.new("Compilation error"))

        get "/assets/app.css"

        expect(last_response.status).to eq(500)
        expect(last_response.body).to include("Asset error: Compilation error")
      end

      it "sets appropriate cache headers" do
        allow(sprockets_env).to receive(:find_asset).with("app.css").and_return(sprockets_asset)

        get "/assets/app.css"

        expect(last_response.headers["ETag"]).to eq('"abc123"')
        expect(last_response.headers["Cache-Control"]).to eq("public, max-age=31536000")
      end
    end
  end
end