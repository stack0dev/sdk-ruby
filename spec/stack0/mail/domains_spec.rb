# frozen_string_literal: true

RSpec.describe Stack0::Mail::Domains do
  let(:client) { test_client }
  let(:domains) { client.mail.domains }

  describe "#list" do
    it "lists domains for a project" do
      stub_stack0_request(:get, "/mail/domains?projectSlug=my-project", response_body: [
        { "id" => "domain_1", "domain" => "example.com", "status" => "verified" },
        { "id" => "domain_2", "domain" => "mail.example.com", "status" => "pending" }
      ])

      result = domains.list(project_slug: "my-project")

      expect(result.length).to eq(2)
      expect(result[0]["domain"]).to eq("example.com")
      expect(result[0]["status"]).to eq("verified")
    end

    it "filters by environment" do
      stub_stack0_request(:get, "/mail/domains?projectSlug=my-project&environment=production", response_body: [
        { "id" => "domain_1", "domain" => "example.com", "status" => "verified" }
      ])

      result = domains.list(project_slug: "my-project", environment: "production")

      expect(result.length).to eq(1)
    end
  end

  describe "#add" do
    it "adds a new domain" do
      stub_stack0_request(:post, "/mail/domains", response_body: {
        "id" => "domain_123",
        "domain" => "newdomain.com",
        "status" => "pending",
        "dnsRecords" => [
          { "type" => "TXT", "name" => "_dmarc", "value" => "v=DMARC1" }
        ]
      })

      result = domains.add(domain: "newdomain.com")

      expect(result["id"]).to eq("domain_123")
      expect(result["domain"]).to eq("newdomain.com")
      expect(result["dnsRecords"]).to be_an(Array)
    end
  end

  describe "#get_dns_records" do
    it "retrieves DNS records for a domain" do
      stub_stack0_request(:get, "/mail/domains/domain_123/dns", response_body: {
        "records" => [
          { "type" => "TXT", "name" => "_dmarc", "value" => "v=DMARC1", "verified" => true },
          { "type" => "CNAME", "name" => "mail", "value" => "mail.stack0.dev", "verified" => false }
        ]
      })

      result = domains.get_dns_records("domain_123")

      expect(result["records"].length).to eq(2)
      expect(result["records"][0]["type"]).to eq("TXT")
    end
  end

  describe "#verify" do
    it "verifies a domain" do
      stub_stack0_request(:post, "/mail/domains/domain_123/verify", response_body: {
        "id" => "domain_123",
        "domain" => "example.com",
        "status" => "verified",
        "verifiedAt" => "2024-01-15T10:00:00Z"
      })

      result = domains.verify("domain_123")

      expect(result["status"]).to eq("verified")
    end

    it "returns pending status when verification fails" do
      stub_stack0_request(:post, "/mail/domains/domain_456/verify", response_body: {
        "id" => "domain_456",
        "domain" => "unverified.com",
        "status" => "pending",
        "verificationError" => "DNS records not found"
      })

      result = domains.verify("domain_456")

      expect(result["status"]).to eq("pending")
      expect(result["verificationError"]).to eq("DNS records not found")
    end
  end

  describe "#delete" do
    it "deletes a domain" do
      stub_stack0_request(:delete, "/mail/domains/domain_123", response_body: {
        "success" => true
      })

      result = domains.delete("domain_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#set_default" do
    it "sets a domain as default" do
      stub_stack0_request(:post, "/mail/domains/domain_123/default", response_body: {
        "id" => "domain_123",
        "domain" => "example.com",
        "isDefault" => true
      })

      result = domains.set_default("domain_123")

      expect(result["isDefault"]).to be(true)
    end
  end
end
