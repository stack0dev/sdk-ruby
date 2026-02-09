# frozen_string_literal: true

RSpec.describe Stack0::Mail::Events do
  let(:client) { test_client }
  let(:events) { client.mail.events }

  describe "#list" do
    it "lists event definitions" do
      stub_stack0_request(:get, "/mail/events", response_body: {
        "events" => [
          { "id" => "evt_1", "name" => "signup", "description" => "User signed up" },
          { "id" => "evt_2", "name" => "purchase", "description" => "User made a purchase" }
        ],
        "total" => 2
      })

      result = events.list

      expect(result["events"].length).to eq(2)
      expect(result["events"][0]["name"]).to eq("signup")
    end

    it "filters by project and environment" do
      stub_stack0_request(:get, "/mail/events?projectSlug=my-project&environment=production", response_body: {
        "events" => [],
        "total" => 0
      })

      result = events.list(project_slug: "my-project", environment: "production")

      expect(result["events"]).to eq([])
    end
  end

  describe "#get" do
    it "retrieves an event definition by ID" do
      stub_stack0_request(:get, "/mail/events/evt_123", response_body: {
        "id" => "evt_123",
        "name" => "purchase",
        "description" => "User made a purchase",
        "propertiesSchema" => {
          "amount" => { "type" => "number" },
          "product" => { "type" => "string" }
        }
      })

      result = events.get("evt_123")

      expect(result["id"]).to eq("evt_123")
      expect(result["propertiesSchema"]["amount"]["type"]).to eq("number")
    end
  end

  describe "#create" do
    it "creates a new event definition" do
      stub_stack0_request(:post, "/mail/events", response_body: {
        "id" => "evt_new",
        "name" => "new_event",
        "description" => "A new event"
      })

      result = events.create(name: "new_event", description: "A new event")

      expect(result["id"]).to eq("evt_new")
      expect(result["name"]).to eq("new_event")
    end

    it "creates an event with properties schema" do
      stub_stack0_request(:post, "/mail/events", response_body: {
        "id" => "evt_schema",
        "name" => "order_placed",
        "propertiesSchema" => {
          "orderId" => { "type" => "string" },
          "total" => { "type" => "number" }
        }
      })

      result = events.create(
        name: "order_placed",
        properties_schema: {
          "orderId" => { "type" => "string" },
          "total" => { "type" => "number" }
        }
      )

      expect(result["propertiesSchema"]["orderId"]["type"]).to eq("string")
    end
  end

  describe "#update" do
    it "updates an event definition" do
      stub_stack0_request(:put, "/mail/events/evt_123", response_body: {
        "id" => "evt_123",
        "name" => "updated_event",
        "description" => "Updated description"
      })

      result = events.update(id: "evt_123", name: "updated_event", description: "Updated description")

      expect(result["name"]).to eq("updated_event")
    end
  end

  describe "#delete" do
    it "deletes an event definition" do
      stub_stack0_request(:delete, "/mail/events/evt_123", response_body: {
        "success" => true
      })

      result = events.delete("evt_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#track" do
    it "tracks a single event" do
      stub_stack0_request(:post, "/mail/events/track", response_body: {
        "success" => true,
        "occurrenceId" => "occ_123"
      })

      result = events.track(event_name: "signup", contact_email: "user@example.com")

      expect(result["success"]).to be(true)
      expect(result["occurrenceId"]).to eq("occ_123")
    end

    it "tracks an event with properties" do
      stub_stack0_request(:post, "/mail/events/track", response_body: {
        "success" => true
      })

      result = events.track(
        event_name: "purchase",
        contact_id: "contact_123",
        properties: { "amount" => 99.99, "product" => "Pro Plan" }
      )

      expect(result["success"]).to be(true)
    end
  end

  describe "#track_batch" do
    it "tracks multiple events in a batch" do
      stub_stack0_request(:post, "/mail/events/track/batch", response_body: {
        "success" => true,
        "tracked" => 5,
        "failed" => 0
      })

      result = events.track_batch(
        events: [
          { eventName: "signup", contactEmail: "user1@example.com" },
          { eventName: "signup", contactEmail: "user2@example.com" }
        ]
      )

      expect(result["tracked"]).to eq(5)
      expect(result["failed"]).to eq(0)
    end
  end

  describe "#list_occurrences" do
    it "lists event occurrences" do
      stub_stack0_request(:get, "/mail/events/occurrences", response_body: {
        "occurrences" => [
          { "id" => "occ_1", "eventName" => "signup", "contactId" => "contact_1" },
          { "id" => "occ_2", "eventName" => "purchase", "contactId" => "contact_2" }
        ],
        "total" => 2
      })

      result = events.list_occurrences

      expect(result["occurrences"].length).to eq(2)
    end

    it "filters by event and contact" do
      stub_stack0_request(:get, "/mail/events/occurrences?eventId=evt_123&contactId=contact_456", response_body: {
        "occurrences" => [],
        "total" => 0
      })

      result = events.list_occurrences(event_id: "evt_123", contact_id: "contact_456")

      expect(result["occurrences"]).to eq([])
    end
  end

  describe "#get_analytics" do
    it "retrieves analytics for an event" do
      stub_stack0_request(:get, "/mail/events/analytics/evt_123", response_body: {
        "totalOccurrences" => 1500,
        "uniqueContacts" => 1200,
        "averagePerDay" => 50,
        "lastOccurredAt" => "2024-01-15T10:00:00Z"
      })

      result = events.get_analytics("evt_123")

      expect(result["totalOccurrences"]).to eq(1500)
      expect(result["uniqueContacts"]).to eq(1200)
    end
  end
end
