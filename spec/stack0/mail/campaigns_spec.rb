# frozen_string_literal: true

RSpec.describe Stack0::Mail::Campaigns do
  let(:client) { test_client }
  let(:campaigns) { client.mail.campaigns }

  describe "#list" do
    it "lists campaigns" do
      stub_stack0_request(:get, "/mail/campaigns", response_body: {
        "campaigns" => [
          { "id" => "camp_1", "name" => "Spring Sale", "status" => "draft" },
          { "id" => "camp_2", "name" => "Welcome Series", "status" => "sent" }
        ],
        "total" => 2
      })

      result = campaigns.list

      expect(result["campaigns"].length).to eq(2)
      expect(result["campaigns"][0]["name"]).to eq("Spring Sale")
    end

    it "filters by status with pagination" do
      stub_stack0_request(:get, "/mail/campaigns?status=sent&limit=10", response_body: {
        "campaigns" => [
          { "id" => "camp_2", "name" => "Welcome Series", "status" => "sent" }
        ],
        "total" => 1
      })

      result = campaigns.list(status: "sent", limit: 10)

      expect(result["campaigns"].length).to eq(1)
    end
  end

  describe "#get" do
    it "retrieves a campaign by ID" do
      stub_stack0_request(:get, "/mail/campaigns/camp_123", response_body: {
        "id" => "camp_123",
        "name" => "Summer Campaign",
        "subject" => "Hot Summer Deals",
        "fromEmail" => "deals@example.com",
        "fromName" => "Deals Team",
        "status" => "draft",
        "audienceId" => "aud_456"
      })

      result = campaigns.get("camp_123")

      expect(result["id"]).to eq("camp_123")
      expect(result["subject"]).to eq("Hot Summer Deals")
    end
  end

  describe "#create" do
    it "creates a new campaign" do
      stub_stack0_request(:post, "/mail/campaigns", response_body: {
        "id" => "camp_new",
        "name" => "New Campaign",
        "subject" => "Check this out",
        "fromEmail" => "hello@example.com",
        "status" => "draft"
      })

      result = campaigns.create(
        name: "New Campaign",
        subject: "Check this out",
        from_email: "hello@example.com"
      )

      expect(result["id"]).to eq("camp_new")
      expect(result["status"]).to eq("draft")
    end

    it "creates a campaign with all options" do
      stub_stack0_request(:post, "/mail/campaigns", response_body: {
        "id" => "camp_full",
        "name" => "Full Campaign",
        "subject" => "Subject",
        "previewText" => "Preview text",
        "fromEmail" => "from@example.com",
        "fromName" => "From Name",
        "replyTo" => "reply@example.com",
        "templateId" => "tmpl_123",
        "audienceId" => "aud_456",
        "tags" => %w[promo sales]
      })

      result = campaigns.create(
        name: "Full Campaign",
        subject: "Subject",
        from_email: "from@example.com",
        from_name: "From Name",
        preview_text: "Preview text",
        reply_to: "reply@example.com",
        template_id: "tmpl_123",
        audience_id: "aud_456",
        tags: %w[promo sales]
      )

      expect(result["previewText"]).to eq("Preview text")
      expect(result["tags"]).to include("promo")
    end
  end

  describe "#update" do
    it "updates a campaign" do
      stub_stack0_request(:put, "/mail/campaigns/camp_123", response_body: {
        "id" => "camp_123",
        "name" => "Updated Campaign",
        "subject" => "New Subject"
      })

      result = campaigns.update(id: "camp_123", name: "Updated Campaign", subject: "New Subject")

      expect(result["name"]).to eq("Updated Campaign")
    end
  end

  describe "#delete" do
    it "deletes a campaign" do
      stub_stack0_request(:delete, "/mail/campaigns/camp_123", response_body: {
        "success" => true
      })

      result = campaigns.delete("camp_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#send_campaign" do
    it "sends a campaign immediately" do
      stub_stack0_request(:post, "/mail/campaigns/camp_123/send", response_body: {
        "id" => "camp_123",
        "status" => "sending",
        "recipientCount" => 1500
      })

      result = campaigns.send_campaign(id: "camp_123", send_now: true)

      expect(result["status"]).to eq("sending")
      expect(result["recipientCount"]).to eq(1500)
    end

    it "schedules a campaign" do
      stub_stack0_request(:post, "/mail/campaigns/camp_123/send", response_body: {
        "id" => "camp_123",
        "status" => "scheduled",
        "scheduledAt" => "2024-02-01T10:00:00Z"
      })

      result = campaigns.send_campaign(
        id: "camp_123",
        scheduled_at: "2024-02-01T10:00:00Z"
      )

      expect(result["status"]).to eq("scheduled")
    end
  end

  describe "#pause" do
    it "pauses a sending campaign" do
      stub_stack0_request(:post, "/mail/campaigns/camp_123/pause", response_body: {
        "id" => "camp_123",
        "status" => "paused"
      })

      result = campaigns.pause("camp_123")

      expect(result["status"]).to eq("paused")
    end
  end

  describe "#cancel" do
    it "cancels a campaign" do
      stub_stack0_request(:post, "/mail/campaigns/camp_123/cancel", response_body: {
        "id" => "camp_123",
        "status" => "cancelled"
      })

      result = campaigns.cancel("camp_123")

      expect(result["status"]).to eq("cancelled")
    end
  end

  describe "#duplicate" do
    it "duplicates a campaign" do
      stub_stack0_request(:post, "/mail/campaigns/camp_123/duplicate", response_body: {
        "id" => "camp_456",
        "name" => "Spring Sale (Copy)",
        "status" => "draft"
      })

      result = campaigns.duplicate("camp_123")

      expect(result["id"]).to eq("camp_456")
      expect(result["name"]).to include("Copy")
    end
  end

  describe "#get_stats" do
    it "retrieves campaign statistics" do
      stub_stack0_request(:get, "/mail/campaigns/camp_123/stats", response_body: {
        "sent" => 1000,
        "delivered" => 980,
        "opened" => 450,
        "clicked" => 120,
        "bounced" => 20,
        "unsubscribed" => 5,
        "openRate" => 0.459,
        "clickRate" => 0.122
      })

      result = campaigns.get_stats("camp_123")

      expect(result["sent"]).to eq(1000)
      expect(result["openRate"]).to eq(0.459)
    end
  end
end
