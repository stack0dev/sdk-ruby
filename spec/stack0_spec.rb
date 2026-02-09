# frozen_string_literal: true

RSpec.describe Stack0 do
  it "has a version number" do
    expect(Stack0::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "allows configuration via block" do
      Stack0.configure do |config|
        config.api_key = "test_key"
        config.base_url = "https://custom.api.com"
        config.timeout = 60
      end

      expect(Stack0.configuration.api_key).to eq("test_key")
      expect(Stack0.configuration.base_url).to eq("https://custom.api.com")
      expect(Stack0.configuration.timeout).to eq(60)
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(Stack0.configuration).to be_a(Stack0::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = Stack0.configuration
      config2 = Stack0.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".client" do
    before do
      Stack0.configure do |config|
        config.api_key = "test_key"
      end
    end

    it "creates a new client with global configuration" do
      client = Stack0.client
      expect(client).to be_a(Stack0::Client)
    end
  end
end
