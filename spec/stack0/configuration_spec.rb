# frozen_string_literal: true

RSpec.describe Stack0::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default base_url" do
      expect(config.base_url).to eq("https://api.stack0.dev/v1")
    end

    it "sets default timeout" do
      expect(config.timeout).to eq(30)
    end

    it "sets cdn_url to nil by default" do
      expect(config.cdn_url).to be_nil
    end

    it "sets api_key to nil by default" do
      expect(config.api_key).to be_nil
    end
  end

  describe "#api_key=" do
    it "allows setting the API key" do
      config.api_key = "my_api_key"
      expect(config.api_key).to eq("my_api_key")
    end
  end

  describe "#base_url=" do
    it "allows setting a custom base URL" do
      config.base_url = "https://custom.api.com"
      expect(config.base_url).to eq("https://custom.api.com")
    end
  end

  describe "#cdn_url=" do
    it "allows setting a custom CDN URL" do
      config.cdn_url = "https://custom.cdn.com"
      expect(config.cdn_url).to eq("https://custom.cdn.com")
    end
  end

  describe "#timeout=" do
    it "allows setting a custom timeout" do
      config.timeout = 60
      expect(config.timeout).to eq(60)
    end
  end
end
