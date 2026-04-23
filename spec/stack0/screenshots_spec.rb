# frozen_string_literal: true

RSpec.describe Stack0::Screenshots::Client do
  let(:client) { test_client }
  let(:screenshots) { client.screenshots }

  describe "#capture" do
    it "creates a screenshot capture job" do
      stub_stack0_request(:post, "/webdata/screenshots", response_body: {
        "id" => "screenshot_123",
        "status" => "pending"
      })

      result = screenshots.capture(url: "https://example.com")

      expect(result["id"]).to eq("screenshot_123")
      expect(result["status"]).to eq("pending")
    end

    it "accepts capture options" do
      stub_stack0_request(:post, "/webdata/screenshots", response_body: {
        "id" => "screenshot_456",
        "status" => "pending"
      })

      result = screenshots.capture(
        url: "https://example.com",
        format: "png",
        full_page: true,
        viewport_width: 1920,
        viewport_height: 1080,
        device_type: "desktop"
      )

      expect(result["id"]).to eq("screenshot_456")
    end

    it "accepts advanced options" do
      stub_stack0_request(:post, "/webdata/screenshots", response_body: {
        "id" => "screenshot_789",
        "status" => "pending"
      })

      result = screenshots.capture(
        url: "https://example.com",
        block_ads: true,
        block_cookie_banners: true,
        dark_mode: true,
        custom_css: "body { background: black; }",
        wait_for_selector: "#main-content"
      )

      expect(result["id"]).to eq("screenshot_789")
    end
  end

  describe "#get" do
    it "retrieves a screenshot by ID" do
      stub_stack0_request(:get, "/webdata/screenshots/screenshot_123", response_body: {
        "id" => "screenshot_123",
        "status" => "completed",
        "imageUrl" => "https://cdn.stack0.dev/screenshots/abc.png",
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:00:05Z"
      })

      result = screenshots.get(id: "screenshot_123")

      expect(result["id"]).to eq("screenshot_123")
      expect(result["status"]).to eq("completed")
      expect(result["imageUrl"]).to include("cdn.stack0.dev")
      expect(result["createdAt"]).to be_a(Time)
      expect(result["completedAt"]).to be_a(Time)
    end

    it "retrieves with environment" do
      stub_stack0_request(:get, "/webdata/screenshots/screenshot_123?environment=production", response_body: {
        "id" => "screenshot_123",
        "status" => "completed"
      })

      result = screenshots.get(id: "screenshot_123", environment: "production")

      expect(result["status"]).to eq("completed")
    end
  end

  describe "#list" do
    it "lists screenshots with filters" do
      stub_stack0_request(:get, "/webdata/screenshots?status=completed&limit=20", response_body: {
        "items" => [
          { "id" => "screenshot_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" },
          { "id" => "screenshot_2", "status" => "completed", "createdAt" => "2024-01-15T11:00:00Z" }
        ],
        "cursor" => nil
      })

      result = screenshots.list(status: "completed", limit: 20)

      expect(result["items"].length).to eq(2)
      expect(result["items"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#delete" do
    it "deletes a screenshot" do
      stub_request(:delete, "https://api.stack0.dev/webdata/screenshots/screenshot_123")
        .with(body: { "id" => "screenshot_123" }.to_json)
        .to_return(
          status: 200,
          body: { "success" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = screenshots.delete(id: "screenshot_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#batch" do
    it "creates batch screenshot jobs" do
      stub_stack0_request(:post, "/webdata/batch/screenshots", response_body: {
        "id" => "batch_123",
        "totalUrls" => 3,
        "status" => "pending"
      })

      result = screenshots.batch(urls: [
        "https://example1.com",
        "https://example2.com",
        "https://example3.com"
      ])

      expect(result["id"]).to eq("batch_123")
      expect(result["totalUrls"]).to eq(3)
    end
  end

  describe "#get_batch_job" do
    it "retrieves a batch job by ID" do
      stub_stack0_request(:get, "/webdata/batch/batch_123", response_body: {
        "id" => "batch_123",
        "status" => "completed",
        "totalUrls" => 3,
        "completedUrls" => 3,
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:05:00Z"
      })

      result = screenshots.get_batch_job(id: "batch_123")

      expect(result["status"]).to eq("completed")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#list_batch_jobs" do
    it "lists batch jobs" do
      stub_stack0_request(:get, "/webdata/batch?type=screenshot", response_body: {
        "items" => [
          { "id" => "batch_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => nil
      })

      result = screenshots.list_batch_jobs

      expect(result["items"].length).to eq(1)
    end
  end

  describe "#cancel_batch_job" do
    it "cancels a batch job" do
      stub_stack0_request(:post, "/webdata/batch/batch_123/cancel", response_body: {
        "success" => true
      })

      result = screenshots.cancel_batch_job(id: "batch_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#capture_and_wait" do
    it "captures and waits for completion" do
      stub_request(:post, "https://api.stack0.dev/webdata/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "screenshot_123", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/screenshots/screenshot_123")
        .to_return(
          status: 200,
          body: {
            "id" => "screenshot_123",
            "status" => "completed",
            "imageUrl" => "https://cdn.stack0.dev/screenshots/abc.png",
            "createdAt" => "2024-01-15T10:00:00Z",
            "completedAt" => "2024-01-15T10:00:05Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = screenshots.capture_and_wait(
        url: "https://example.com",
        poll_interval: 0.1,
        timeout: 5
      )

      expect(result["status"]).to eq("completed")
      expect(result["imageUrl"]).to include("cdn.stack0.dev")
    end

    it "raises error on failure" do
      stub_request(:post, "https://api.stack0.dev/webdata/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "screenshot_fail", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/screenshots/screenshot_fail")
        .to_return(
          status: 200,
          body: { "id" => "screenshot_fail", "status" => "failed", "error" => "URL not reachable" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        screenshots.capture_and_wait(url: "https://unreachable.example.com", poll_interval: 0.1, timeout: 5)
      end.to raise_error(Stack0::Error, "URL not reachable")
    end

    it "raises timeout error" do
      stub_request(:post, "https://api.stack0.dev/webdata/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "screenshot_slow", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/screenshots/screenshot_slow")
        .to_return(
          status: 200,
          body: { "id" => "screenshot_slow", "status" => "processing" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        screenshots.capture_and_wait(url: "https://slow.example.com", poll_interval: 0.05, timeout: 0.1)
      end.to raise_error(Stack0::TimeoutError)
    end
  end

  describe "#batch_and_wait" do
    it "creates batch and waits for completion" do
      stub_request(:post, "https://api.stack0.dev/webdata/batch/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "batch_123", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/batch/batch_123")
        .to_return(
          status: 200,
          body: {
            "id" => "batch_123",
            "status" => "completed",
            "totalUrls" => 2,
            "createdAt" => "2024-01-15T10:00:00Z",
            "completedAt" => "2024-01-15T10:05:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = screenshots.batch_and_wait(
        urls: %w[https://example1.com https://example2.com],
        poll_interval: 0.1,
        timeout: 5
      )

      expect(result["status"]).to eq("completed")
    end
  end

  describe "#create_schedule" do
    it "creates a scheduled screenshot job" do
      stub_stack0_request(:post, "/webdata/schedules", response_body: {
        "id" => "sched_123",
        "name" => "Daily Screenshot",
        "type" => "screenshot",
        "frequency" => "daily",
        "isActive" => true
      })

      result = screenshots.create_schedule(
        name: "Daily Screenshot",
        url: "https://example.com",
        frequency: "daily",
        config: { format: "png", full_page: true }
      )

      expect(result["id"]).to eq("sched_123")
    end
  end

  describe "#get_schedule" do
    it "retrieves a schedule by ID" do
      stub_stack0_request(:get, "/webdata/schedules/sched_123", response_body: {
        "id" => "sched_123",
        "name" => "Daily Screenshot",
        "createdAt" => "2024-01-15T10:00:00Z",
        "nextRunAt" => "2024-01-16T10:00:00Z"
      })

      result = screenshots.get_schedule(id: "sched_123")

      expect(result["createdAt"]).to be_a(Time)
      expect(result["nextRunAt"]).to be_a(Time)
    end
  end

  describe "#list_schedules" do
    it "lists schedules" do
      stub_stack0_request(:get, "/webdata/schedules?type=screenshot", response_body: {
        "items" => [
          { "id" => "sched_1", "name" => "Schedule 1", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => nil
      })

      result = screenshots.list_schedules

      expect(result["items"].length).to eq(1)
      expect(result["items"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#toggle_schedule" do
    it "toggles a schedule" do
      stub_stack0_request(:post, "/webdata/schedules/sched_123/toggle", response_body: {
        "id" => "sched_123",
        "isActive" => false
      })

      result = screenshots.toggle_schedule(id: "sched_123")

      expect(result["isActive"]).to be(false)
    end
  end

  describe "#delete_schedule" do
    it "deletes a schedule" do
      stub_request(:delete, "https://api.stack0.dev/webdata/schedules/sched_123")
        .with(body: { "id" => "sched_123" }.to_json)
        .to_return(
          status: 200,
          body: { "success" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = screenshots.delete_schedule(id: "sched_123")

      expect(result["success"]).to be(true)
    end
  end
end
