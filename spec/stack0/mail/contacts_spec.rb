# frozen_string_literal: true

RSpec.describe Stack0::Mail::Contacts do
  let(:client) { test_client }
  let(:contacts) { client.mail.contacts }

  describe "#list" do
    it "lists contacts" do
      stub_stack0_request(:get, "/mail/contacts", response_body: {
        "contacts" => [
          { "id" => "contact_1", "email" => "user1@example.com", "firstName" => "John" },
          { "id" => "contact_2", "email" => "user2@example.com", "firstName" => "Jane" }
        ],
        "total" => 2
      })

      result = contacts.list

      expect(result["contacts"].length).to eq(2)
      expect(result["contacts"][0]["email"]).to eq("user1@example.com")
    end

    it "filters by environment and status with pagination" do
      stub_stack0_request(:get, "/mail/contacts?environment=production&status=active&limit=25&offset=0", response_body: {
        "contacts" => [],
        "total" => 0
      })

      result = contacts.list(environment: "production", status: "active", limit: 25, offset: 0)

      expect(result["contacts"]).to eq([])
    end

    it "supports search" do
      stub_stack0_request(:get, "/mail/contacts?search=john", response_body: {
        "contacts" => [
          { "id" => "contact_1", "email" => "john@example.com", "firstName" => "John" }
        ],
        "total" => 1
      })

      result = contacts.list(search: "john")

      expect(result["contacts"].length).to eq(1)
    end
  end

  describe "#get" do
    it "retrieves a contact by ID" do
      stub_stack0_request(:get, "/mail/contacts/contact_123", response_body: {
        "id" => "contact_123",
        "email" => "user@example.com",
        "firstName" => "John",
        "lastName" => "Doe",
        "status" => "active",
        "metadata" => { "plan" => "pro" }
      })

      result = contacts.get("contact_123")

      expect(result["id"]).to eq("contact_123")
      expect(result["email"]).to eq("user@example.com")
      expect(result["metadata"]["plan"]).to eq("pro")
    end
  end

  describe "#create" do
    it "creates a new contact" do
      stub_stack0_request(:post, "/mail/contacts", response_body: {
        "id" => "contact_new",
        "email" => "newuser@example.com",
        "status" => "active"
      })

      result = contacts.create(email: "newuser@example.com")

      expect(result["id"]).to eq("contact_new")
      expect(result["email"]).to eq("newuser@example.com")
    end

    it "creates a contact with all fields" do
      stub_stack0_request(:post, "/mail/contacts", response_body: {
        "id" => "contact_full",
        "email" => "full@example.com",
        "firstName" => "John",
        "lastName" => "Doe",
        "metadata" => { "source" => "signup" }
      })

      result = contacts.create(
        email: "full@example.com",
        first_name: "John",
        last_name: "Doe",
        metadata: { "source" => "signup" },
        environment: "production"
      )

      expect(result["firstName"]).to eq("John")
      expect(result["metadata"]["source"]).to eq("signup")
    end
  end

  describe "#update" do
    it "updates a contact" do
      stub_stack0_request(:put, "/mail/contacts/contact_123", response_body: {
        "id" => "contact_123",
        "email" => "updated@example.com",
        "firstName" => "Jane"
      })

      result = contacts.update(id: "contact_123", email: "updated@example.com", first_name: "Jane")

      expect(result["email"]).to eq("updated@example.com")
      expect(result["firstName"]).to eq("Jane")
    end

    it "updates contact status" do
      stub_stack0_request(:put, "/mail/contacts/contact_123", response_body: {
        "id" => "contact_123",
        "status" => "unsubscribed"
      })

      result = contacts.update(id: "contact_123", status: "unsubscribed")

      expect(result["status"]).to eq("unsubscribed")
    end
  end

  describe "#delete" do
    it "deletes a contact" do
      stub_stack0_request(:delete, "/mail/contacts/contact_123", response_body: {
        "success" => true
      })

      result = contacts.delete("contact_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#import" do
    it "imports contacts in bulk" do
      stub_stack0_request(:post, "/mail/contacts/import", response_body: {
        "imported" => 100,
        "skipped" => 5,
        "failed" => 2,
        "errors" => [
          { "email" => "invalid", "error" => "Invalid email format" }
        ]
      })

      result = contacts.import(
        contacts: [
          { "email" => "user1@example.com", "firstName" => "User 1" },
          { "email" => "user2@example.com", "firstName" => "User 2" }
        ]
      )

      expect(result["imported"]).to eq(100)
      expect(result["skipped"]).to eq(5)
      expect(result["failed"]).to eq(2)
    end

    it "imports contacts with audience assignment" do
      stub_stack0_request(:post, "/mail/contacts/import", response_body: {
        "imported" => 50,
        "skipped" => 0,
        "failed" => 0
      })

      result = contacts.import(
        contacts: [{ "email" => "user@example.com" }],
        environment: "production",
        audience_id: "aud_123"
      )

      expect(result["imported"]).to eq(50)
    end
  end
end
