# frozen_string_literal: true

RSpec.describe Stack0::Client do
  subject(:client) { described_class.new(api_key: "test_api_key") }

  describe "#initialize" do
    it "creates a client with the required api_key" do
      expect(client).to be_a(described_class)
    end

    it "accepts optional configuration" do
      custom_client = described_class.new(
        api_key: "test_key",
        base_url: "https://custom.api.com",
        cdn_url: "https://custom.cdn.com",
        timeout: 60
      )
      expect(custom_client).to be_a(described_class)
    end
  end

  describe "sub-clients" do
    it "provides access to mail client" do
      expect(client.mail).to be_a(Stack0::Mail::Client)
    end

    it "provides access to cdn client" do
      expect(client.cdn).to be_a(Stack0::CDN::Client)
    end

    it "provides access to screenshots client" do
      expect(client.screenshots).to be_a(Stack0::Screenshots::Client)
    end

    it "provides access to extraction client" do
      expect(client.extraction).to be_a(Stack0::Extraction::Client)
    end

    it "provides access to integrations client" do
      expect(client.integrations).to be_a(Stack0::Integrations::Client)
    end

    it "provides access to marketing client" do
      expect(client.marketing).to be_a(Stack0::Marketing::Client)
    end

    it "provides access to webdata client" do
      expect(client.webdata).to be_a(Stack0::Webdata::Client)
    end
  end
end
