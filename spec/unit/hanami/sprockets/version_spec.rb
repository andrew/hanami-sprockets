# frozen_string_literal: true

RSpec.describe "Hanami::Assets::VERSION" do
  it "returns the version string" do
    expect(Hanami::Assets::VERSION).to eq("0.2.0")
  end
end