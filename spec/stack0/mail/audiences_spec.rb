# frozen_string_literal: true

RSpec.describe Stack0::Mail::Audiences do
  let(:client) { test_client }
  let(:audiences) { client.mail.audiences }

  describe "#list" do
    it "lists audiences" do
      stub_stack0_request(:get, "/mail/audiences", response_body: {
        "audiences" => [
          { "id" => "aud_1", "name" => "Newsletter", "contactCount" => 1500 },
          { "id" => "aud_2", "name" => "Beta Users", "contactCount" => 250 }
        ],
        "total" => 2
      })

      result = audiences.list

      expect(result["audiences"].length).to eq(2)
      expect(result["audiences"][0]["name"]).to eq("Newsletter")
    end

    it "filters by environment with pagination" do
      stub_stack0_request(:get, "/mail/audiences?environment=production&limit=10&offset=0", response_body: {
        "audiences" => [],
        "total" => 0
      })

      result = audiences.list(environment: "production", limit: 10, offset: 0)

      expect(result["audiences"]).to eq([])
    end

    it "supports search" do
      stub_stack0_request(:get, "/mail/audiences?search=newsletter", response_body: {
        "audiences" => [
          { "id" => "aud_1", "name" => "Newsletter" }
        ],
        "total" => 1
      })

      result = audiences.list(search: "newsletter")

      expect(result["audiences"].length).to eq(1)
    end
  end

  describe "#get" do
    it "retrieves an audience by ID" do
      stub_stack0_request(:get, "/mail/audiences/aud_123", response_body: {
        "id" => "aud_123",
        "name" => "VIP Customers",
        "description" => "High-value customers",
        "contactCount" => 500
      })

      result = audiences.get("aud_123")

      expect(result["id"]).to eq("aud_123")
      expect(result["name"]).to eq("VIP Customers")
    end
  end

  describe "#create" do
    it "creates a new audience" do
      stub_stack0_request(:post, "/mail/audiences", response_body: {
        "id" => "aud_new",
        "name" => "New Audience",
        "description" => "A new audience",
        "contactCount" => 0
      })

      result = audiences.create(name: "New Audience", description: "A new audience")

      expect(result["id"]).to eq("aud_new")
      expect(result["name"]).to eq("New Audience")
    end

    it "creates an audience with environment" do
      stub_stack0_request(:post, "/mail/audiences", response_body: {
        "id" => "aud_prod",
        "name" => "Production Audience"
      })

      result = audiences.create(name: "Production Audience", environment: "production")

      expect(result["id"]).to eq("aud_prod")
    end
  end

  describe "#update" do
    it "updates an audience" do
      stub_stack0_request(:put, "/mail/audiences/aud_123", response_body: {
        "id" => "aud_123",
        "name" => "Updated Name",
        "description" => "Updated description"
      })

      result = audiences.update(id: "aud_123", name: "Updated Name", description: "Updated description")

      expect(result["name"]).to eq("Updated Name")
    end
  end

  describe "#delete" do
    it "deletes an audience" do
      stub_stack0_request(:delete, "/mail/audiences/aud_123", response_body: {
        "success" => true
      })

      result = audiences.delete("aud_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#list_contacts" do
    it "lists contacts in an audience" do
      stub_stack0_request(:get, "/mail/audiences/aud_123/contacts", response_body: {
        "contacts" => [
          { "id" => "contact_1", "email" => "user1@example.com" },
          { "id" => "contact_2", "email" => "user2@example.com" }
        ],
        "total" => 2
      })

      result = audiences.list_contacts(id: "aud_123")

      expect(result["contacts"].length).to eq(2)
    end

    it "filters contacts with pagination" do
      stub_stack0_request(:get, "/mail/audiences/aud_123/contacts?status=active&limit=50&offset=0", response_body: {
        "contacts" => [],
        "total" => 0
      })

      result = audiences.list_contacts(id: "aud_123", status: "active", limit: 50, offset: 0)

      expect(result["contacts"]).to eq([])
    end
  end

  describe "#add_contacts" do
    it "adds contacts to an audience" do
      stub_stack0_request(:post, "/mail/audiences/aud_123/contacts", response_body: {
        "added" => 3
      })

      result = audiences.add_contacts(id: "aud_123", contact_ids: %w[contact_1 contact_2 contact_3])

      expect(result["added"]).to eq(3)
    end
  end

  describe "#remove_contacts" do
    it "removes contacts from an audience" do
      stub_request(:delete, "https://api.stack0.dev/mail/audiences/aud_123/contacts")
        .with(body: { contactIds: %w[contact_1 contact_2] }.to_json)
        .to_return(
          status: 200,
          body: { "removed" => 2 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = audiences.remove_contacts(id: "aud_123", contact_ids: %w[contact_1 contact_2])

      expect(result["removed"]).to eq(2)
    end
  end
end
