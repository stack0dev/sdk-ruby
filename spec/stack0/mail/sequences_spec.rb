# frozen_string_literal: true

RSpec.describe Stack0::Mail::Sequences do
  let(:client) { test_client }
  let(:sequences) { client.mail.sequences }

  describe "#list" do
    it "lists sequences" do
      stub_stack0_request(:get, "/mail/sequences", response_body: {
        "sequences" => [
          { "id" => "seq_1", "name" => "Onboarding", "status" => "active" },
          { "id" => "seq_2", "name" => "Win Back", "status" => "draft" }
        ],
        "total" => 2
      })

      result = sequences.list

      expect(result["sequences"].length).to eq(2)
      expect(result["sequences"][0]["name"]).to eq("Onboarding")
    end

    it "filters by trigger type" do
      stub_stack0_request(:get, "/mail/sequences?triggerType=event", response_body: {
        "sequences" => [
          { "id" => "seq_1", "name" => "Event Triggered", "triggerType" => "event" }
        ],
        "total" => 1
      })

      result = sequences.list(trigger_type: "event")

      expect(result["sequences"].length).to eq(1)
    end
  end

  describe "#get" do
    it "retrieves a sequence with nodes and connections" do
      stub_stack0_request(:get, "/mail/sequences/seq_123", response_body: {
        "id" => "seq_123",
        "name" => "Welcome Flow",
        "status" => "active",
        "triggerType" => "contact_created",
        "nodes" => [
          { "id" => "node_1", "nodeType" => "trigger", "name" => "Start" },
          { "id" => "node_2", "nodeType" => "email", "name" => "Welcome Email" }
        ],
        "connections" => [
          { "id" => "conn_1", "sourceNodeId" => "node_1", "targetNodeId" => "node_2" }
        ]
      })

      result = sequences.get("seq_123")

      expect(result["id"]).to eq("seq_123")
      expect(result["nodes"].length).to eq(2)
      expect(result["connections"].length).to eq(1)
    end
  end

  describe "#create" do
    it "creates a new sequence" do
      stub_stack0_request(:post, "/mail/sequences", response_body: {
        "id" => "seq_new",
        "name" => "New Sequence",
        "triggerType" => "manual",
        "status" => "draft"
      })

      result = sequences.create(name: "New Sequence", trigger_type: "manual")

      expect(result["id"]).to eq("seq_new")
    end
  end

  describe "#update" do
    it "updates a sequence" do
      stub_stack0_request(:put, "/mail/sequences/seq_123", response_body: {
        "id" => "seq_123",
        "name" => "Updated Sequence",
        "description" => "Updated description"
      })

      result = sequences.update(id: "seq_123", name: "Updated Sequence", description: "Updated description")

      expect(result["name"]).to eq("Updated Sequence")
    end
  end

  describe "#delete" do
    it "deletes a sequence" do
      stub_stack0_request(:delete, "/mail/sequences/seq_123", response_body: {
        "success" => true
      })

      result = sequences.delete("seq_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#publish" do
    it "publishes a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/publish", response_body: {
        "id" => "seq_123",
        "status" => "active"
      })

      result = sequences.publish("seq_123")

      expect(result["status"]).to eq("active")
    end
  end

  describe "#pause" do
    it "pauses a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/pause", response_body: {
        "id" => "seq_123",
        "status" => "paused"
      })

      result = sequences.pause("seq_123")

      expect(result["status"]).to eq("paused")
    end
  end

  describe "#resume" do
    it "resumes a paused sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/resume", response_body: {
        "id" => "seq_123",
        "status" => "active"
      })

      result = sequences.resume("seq_123")

      expect(result["status"]).to eq("active")
    end
  end

  describe "#archive" do
    it "archives a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/archive", response_body: {
        "id" => "seq_123",
        "status" => "archived"
      })

      result = sequences.archive("seq_123")

      expect(result["status"]).to eq("archived")
    end
  end

  describe "#duplicate" do
    it "duplicates a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/duplicate", response_body: {
        "id" => "seq_456",
        "name" => "Onboarding (Copy)",
        "status" => "draft"
      })

      result = sequences.duplicate("seq_123")

      expect(result["id"]).to eq("seq_456")
    end

    it "duplicates with a custom name" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/duplicate", response_body: {
        "id" => "seq_456",
        "name" => "Custom Name",
        "status" => "draft"
      })

      result = sequences.duplicate("seq_123", name: "Custom Name")

      expect(result["name"]).to eq("Custom Name")
    end
  end

  describe "#create_node" do
    it "creates a node in a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/nodes", response_body: {
        "id" => "node_new",
        "nodeType" => "email",
        "name" => "Follow Up Email",
        "positionX" => 100,
        "positionY" => 200
      })

      result = sequences.create_node(
        sequence_id: "seq_123",
        node_type: "email",
        name: "Follow Up Email",
        position_x: 100,
        position_y: 200
      )

      expect(result["id"]).to eq("node_new")
      expect(result["nodeType"]).to eq("email")
    end
  end

  describe "#update_node" do
    it "updates a node" do
      stub_stack0_request(:put, "/mail/sequences/seq_123/nodes/node_456", response_body: {
        "id" => "node_456",
        "name" => "Updated Node Name"
      })

      result = sequences.update_node(
        sequence_id: "seq_123",
        node_id: "node_456",
        name: "Updated Node Name"
      )

      expect(result["name"]).to eq("Updated Node Name")
    end
  end

  describe "#update_node_position" do
    it "updates node position" do
      stub_stack0_request(:put, "/mail/sequences/seq_123/nodes/node_456/position", response_body: {
        "id" => "node_456",
        "positionX" => 300,
        "positionY" => 400
      })

      result = sequences.update_node_position(
        sequence_id: "seq_123",
        node_id: "node_456",
        position_x: 300,
        position_y: 400
      )

      expect(result["positionX"]).to eq(300)
    end
  end

  describe "#delete_node" do
    it "deletes a node" do
      stub_stack0_request(:delete, "/mail/sequences/seq_123/nodes/node_456", response_body: {
        "success" => true
      })

      result = sequences.delete_node(sequence_id: "seq_123", node_id: "node_456")

      expect(result["success"]).to be(true)
    end
  end

  describe "#set_node_email" do
    it "sets email content for a node" do
      stub_stack0_request(:put, "/mail/sequences/seq_123/nodes/node_456/email", response_body: {
        "id" => "node_456",
        "subject" => "Welcome!",
        "html" => "<h1>Welcome</h1>"
      })

      result = sequences.set_node_email(
        sequence_id: "seq_123",
        node_id: "node_456",
        subject: "Welcome!",
        html: "<h1>Welcome</h1>"
      )

      expect(result["subject"]).to eq("Welcome!")
    end
  end

  describe "#set_node_timer" do
    it "sets timer configuration for a node" do
      stub_stack0_request(:put, "/mail/sequences/seq_123/nodes/node_456/timer", response_body: {
        "id" => "node_456",
        "delayAmount" => 3,
        "delayUnit" => "days"
      })

      result = sequences.set_node_timer(
        sequence_id: "seq_123",
        node_id: "node_456",
        delay_amount: 3,
        delay_unit: "days"
      )

      expect(result["delayAmount"]).to eq(3)
      expect(result["delayUnit"]).to eq("days")
    end
  end

  describe "#create_connection" do
    it "creates a connection between nodes" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/connections", response_body: {
        "id" => "conn_new",
        "sourceNodeId" => "node_1",
        "targetNodeId" => "node_2"
      })

      result = sequences.create_connection(
        sequence_id: "seq_123",
        source_node_id: "node_1",
        target_node_id: "node_2"
      )

      expect(result["id"]).to eq("conn_new")
    end
  end

  describe "#delete_connection" do
    it "deletes a connection" do
      stub_stack0_request(:delete, "/mail/sequences/seq_123/connections/conn_456", response_body: {
        "success" => true
      })

      result = sequences.delete_connection(sequence_id: "seq_123", connection_id: "conn_456")

      expect(result["success"]).to be(true)
    end
  end

  describe "#list_entries" do
    it "lists contacts in a sequence" do
      stub_stack0_request(:get, "/mail/sequences/seq_123/entries", response_body: {
        "entries" => [
          { "id" => "entry_1", "contactId" => "contact_1", "status" => "active" },
          { "id" => "entry_2", "contactId" => "contact_2", "status" => "completed" }
        ],
        "total" => 2
      })

      result = sequences.list_entries(sequence_id: "seq_123")

      expect(result["entries"].length).to eq(2)
    end
  end

  describe "#add_contact" do
    it "adds a contact to a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/add-contact", response_body: {
        "id" => "entry_new",
        "contactId" => "contact_123",
        "status" => "active"
      })

      result = sequences.add_contact(sequence_id: "seq_123", contact_id: "contact_123")

      expect(result["contactId"]).to eq("contact_123")
    end
  end

  describe "#remove_contact" do
    it "removes a contact from a sequence" do
      stub_stack0_request(:post, "/mail/sequences/seq_123/remove-contact", response_body: {
        "success" => true
      })

      result = sequences.remove_contact(sequence_id: "seq_123", entry_id: "entry_456")

      expect(result["success"]).to be(true)
    end
  end

  describe "#get_analytics" do
    it "retrieves sequence analytics" do
      stub_stack0_request(:get, "/mail/sequences/seq_123/analytics", response_body: {
        "totalEntered" => 500,
        "totalCompleted" => 450,
        "totalActive" => 30,
        "totalExited" => 20,
        "completionRate" => 0.9
      })

      result = sequences.get_analytics("seq_123")

      expect(result["totalEntered"]).to eq(500)
      expect(result["completionRate"]).to eq(0.9)
    end
  end
end
