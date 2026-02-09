# frozen_string_literal: true

RSpec.describe Stack0::Marketing::Client do
  let(:client) { test_client }
  let(:marketing) { client.marketing }

  describe "#discover_trends" do
    it "discovers new trends" do
      stub_stack0_request(:post, "/marketing/trends/discover", response_body: {
        "trends_discovered" => 5,
        "trends" => [
          { "id" => "trend_1", "topic" => "AI Tools", "score" => 0.95 }
        ]
      })

      result = marketing.discover_trends(project_slug: "my-project", environment: "production")

      expect(result["trends_discovered"]).to eq(5)
    end
  end

  describe "#list_trends" do
    it "lists trends for a project" do
      stub_stack0_request(:get, "/marketing/trends?projectSlug=my-project&environment=production", response_body: [
        { "id" => "trend_1", "topic" => "AI", "status" => "active" },
        { "id" => "trend_2", "topic" => "Cloud", "status" => "active" }
      ])

      result = marketing.list_trends(project_slug: "my-project", environment: "production")

      expect(result.length).to eq(2)
    end
  end

  describe "#get_trend" do
    it "retrieves a trend by ID" do
      stub_stack0_request(:get, "/marketing/trends/trend_123", response_body: {
        "id" => "trend_123",
        "topic" => "Machine Learning",
        "status" => "active",
        "firstSeenAt" => "2024-01-10T00:00:00Z",
        "lastUpdatedAt" => "2024-01-15T12:00:00Z"
      })

      result = marketing.get_trend("trend_123")

      expect(result["id"]).to eq("trend_123")
      expect(result["firstSeenAt"]).to be_a(Time)
    end
  end

  describe "#update_trend_status" do
    it "updates trend status" do
      stub_stack0_request(:patch, "/marketing/trends/trend_123/status", response_body: {
        "id" => "trend_123",
        "status" => "dismissed"
      })

      result = marketing.update_trend_status(trend_id: "trend_123", status: "dismissed")

      expect(result["status"]).to eq("dismissed")
    end
  end

  describe "#generate_opportunities" do
    it "generates content opportunities" do
      stub_stack0_request(:post, "/marketing/opportunities/generate", response_body: {
        "opportunities_generated" => 3,
        "opportunities" => [
          { "id" => "opp_1", "title" => "AI Guide", "priority" => "high" }
        ]
      })

      result = marketing.generate_opportunities(project_slug: "my-project", environment: "production")

      expect(result["opportunities_generated"]).to eq(3)
    end
  end

  describe "#list_opportunities" do
    it "lists opportunities" do
      stub_stack0_request(:get, "/marketing/opportunities?projectSlug=my-project&environment=production", response_body: [
        { "id" => "opp_1", "title" => "AI Guide", "status" => "active" }
      ])

      result = marketing.list_opportunities(project_slug: "my-project", environment: "production")

      expect(result.length).to eq(1)
    end
  end

  describe "#dismiss_opportunity" do
    it "dismisses an opportunity" do
      stub_stack0_request(:post, "/marketing/opportunities/opp_123/dismiss", response_body: {
        "success" => true
      })

      result = marketing.dismiss_opportunity("opp_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#create_content" do
    it "creates new content" do
      stub_stack0_request(:post, "/marketing/content", response_body: {
        "id" => "content_123",
        "title" => "AI Tools Guide",
        "contentType" => "tiktok_slideshow",
        "status" => "draft",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = marketing.create_content(
        project_slug: "my-project",
        environment: "production",
        content_type: "tiktok_slideshow",
        title: "AI Tools Guide"
      )

      expect(result["id"]).to eq("content_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#list_content" do
    it "lists content" do
      stub_stack0_request(:get, "/marketing/content?projectSlug=my-project&environment=production", response_body: [
        { "id" => "content_1", "title" => "Guide 1", "status" => "published", "createdAt" => "2024-01-15T10:00:00Z" }
      ])

      result = marketing.list_content(project_slug: "my-project", environment: "production")

      expect(result.length).to eq(1)
      expect(result[0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#get_content" do
    it "retrieves content by ID" do
      stub_stack0_request(:get, "/marketing/content/content_123", response_body: {
        "id" => "content_123",
        "title" => "My Content",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = marketing.get_content("content_123")

      expect(result["id"]).to eq("content_123")
    end
  end

  describe "#update_content" do
    it "updates content" do
      stub_stack0_request(:patch, "/marketing/content/content_123", response_body: {
        "id" => "content_123",
        "title" => "Updated Title",
        "updatedAt" => "2024-01-16T10:00:00Z"
      })

      result = marketing.update_content(content_id: "content_123", title: "Updated Title")

      expect(result["title"]).to eq("Updated Title")
    end
  end

  describe "#approve_content" do
    it "approves content" do
      stub_stack0_request(:post, "/marketing/content/content_123/approve", response_body: {
        "id" => "content_123",
        "approvalStatus" => "approved",
        "reviewedAt" => "2024-01-16T10:00:00Z"
      })

      result = marketing.approve_content(content_id: "content_123")

      expect(result["approvalStatus"]).to eq("approved")
    end
  end

  describe "#reject_content" do
    it "rejects content" do
      stub_stack0_request(:post, "/marketing/content/content_123/reject", response_body: {
        "id" => "content_123",
        "approvalStatus" => "rejected",
        "reviewNotes" => "Needs revision"
      })

      result = marketing.reject_content(content_id: "content_123", review_notes: "Needs revision")

      expect(result["approvalStatus"]).to eq("rejected")
    end
  end

  describe "#delete_content" do
    it "deletes content" do
      stub_stack0_request(:delete, "/marketing/content/content_123", response_body: {
        "success" => true
      })

      result = marketing.delete_content("content_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#create_script" do
    it "creates a new script" do
      stub_stack0_request(:post, "/marketing/scripts", response_body: {
        "id" => "script_123",
        "hook" => "Did you know...",
        "cta" => "Follow for more!",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = marketing.create_script(
        project_slug: "my-project",
        environment: "production",
        hook: "Did you know...",
        slides: [{ "text" => "Slide 1" }],
        cta: "Follow for more!"
      )

      expect(result["id"]).to eq("script_123")
    end
  end

  describe "#schedule_content" do
    it "schedules content for publishing" do
      stub_stack0_request(:post, "/marketing/calendar/schedule", response_body: {
        "id" => "entry_123",
        "contentId" => "content_456",
        "scheduledFor" => "2024-02-01T10:00:00Z",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = marketing.schedule_content(
        project_slug: "my-project",
        content_id: "content_456",
        scheduled_for: Time.parse("2024-02-01T10:00:00Z")
      )

      expect(result["scheduledFor"]).to be_a(Time)
    end
  end

  describe "#list_calendar_entries" do
    it "lists calendar entries" do
      stub_stack0_request(:get, "/marketing/calendar?projectSlug=my-project", response_body: [
        { "id" => "entry_1", "scheduledFor" => "2024-02-01T10:00:00Z", "createdAt" => "2024-01-15T10:00:00Z" }
      ])

      result = marketing.list_calendar_entries(project_slug: "my-project")

      expect(result.length).to eq(1)
      expect(result[0]["scheduledFor"]).to be_a(Time)
    end
  end

  describe "#create_asset_job" do
    it "creates an asset generation job" do
      stub_stack0_request(:post, "/marketing/assets/jobs", response_body: {
        "id" => "job_123",
        "jobType" => "slide_generation",
        "status" => "pending",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = marketing.create_asset_job(
        project_slug: "my-project",
        content_id: "content_456",
        job_type: "slide_generation"
      )

      expect(result["id"]).to eq("job_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#get_analytics_overview" do
    it "retrieves analytics overview" do
      stub_stack0_request(:get, "/marketing/analytics/overview?projectSlug=my-project&environment=production",
                          response_body: {
                            "trendsDiscovered" => 50,
                            "opportunitiesGenerated" => 30,
                            "contentCreated" => 20,
                            "contentPublished" => 15
                          })

      result = marketing.get_analytics_overview(project_slug: "my-project", environment: "production")

      expect(result["trendsDiscovered"]).to eq(50)
    end
  end

  describe "#get_settings" do
    it "retrieves marketing settings" do
      stub_stack0_request(:get, "/marketing/settings?projectSlug=my-project", response_body: {
        "brandVoice" => "Professional and friendly",
        "monitoredKeywords" => %w[AI Cloud DevOps]
      })

      result = marketing.get_settings(project_slug: "my-project")

      expect(result["brandVoice"]).to eq("Professional and friendly")
    end
  end

  describe "#update_settings" do
    it "updates marketing settings" do
      stub_stack0_request(:post, "/marketing/settings", response_body: {
        "success" => true
      })

      result = marketing.update_settings(
        project_slug: "my-project",
        brand_voice: "Casual and fun",
        monitored_keywords: %w[startup growth]
      )

      expect(result["success"]).to be(true)
    end
  end

  describe "#get_current_usage" do
    it "retrieves current usage" do
      stub_stack0_request(:get, "/marketing/usage/current?projectSlug=my-project", response_body: {
        "trendsDiscovered" => 10,
        "opportunitiesGenerated" => 5,
        "contentCreated" => 3,
        "periodStart" => "2024-01-01T00:00:00Z",
        "periodEnd" => "2024-01-31T23:59:59Z"
      })

      result = marketing.get_current_usage(project_slug: "my-project")

      expect(result["trendsDiscovered"]).to eq(10)
      expect(result["periodStart"]).to be_a(Time)
    end
  end
end
