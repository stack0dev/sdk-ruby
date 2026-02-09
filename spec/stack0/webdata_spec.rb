# frozen_string_literal: true

RSpec.describe Stack0::Webdata::Client do
  let(:client) { test_client }
  let(:webdata) { client.webdata }

  describe "#screenshot" do
    it "creates a screenshot job" do
      stub_stack0_request(:post, "/webdata/screenshots", response_body: {
        "id" => "ss_123",
        "status" => "pending",
        "url" => "https://example.com"
      })

      result = webdata.screenshot(url: "https://example.com")

      expect(result["id"]).to eq("ss_123")
      expect(result["status"]).to eq("pending")
    end

    it "creates a screenshot with options" do
      stub_stack0_request(:post, "/webdata/screenshots", response_body: {
        "id" => "ss_456",
        "status" => "pending"
      })

      result = webdata.screenshot(
        url: "https://example.com",
        format: "png",
        full_page: true,
        device_type: "desktop"
      )

      expect(result["id"]).to eq("ss_456")
    end
  end

  describe "#get_screenshot" do
    it "retrieves a screenshot by ID" do
      stub_stack0_request(:get, "/webdata/screenshots/ss_123", response_body: {
        "id" => "ss_123",
        "status" => "completed",
        "imageUrl" => "https://cdn.stack0.io/screenshots/abc.png",
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:00:05Z"
      })

      result = webdata.get_screenshot(id: "ss_123")

      expect(result["id"]).to eq("ss_123")
      expect(result["createdAt"]).to be_a(Time)
      expect(result["completedAt"]).to be_a(Time)
    end
  end

  describe "#list_screenshots" do
    it "lists screenshots with pagination" do
      stub_stack0_request(:get, "/webdata/screenshots?status=completed&limit=10", response_body: {
        "items" => [
          { "id" => "ss_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => "next_cursor"
      })

      result = webdata.list_screenshots(status: "completed", limit: 10)

      expect(result["items"].length).to eq(1)
      expect(result["items"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#delete_screenshot" do
    it "deletes a screenshot" do
      stub_stack0_request(:delete, "/webdata/screenshots/ss_123", response_body: {
        "success" => true
      })

      result = webdata.delete_screenshot(id: "ss_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#screenshot_and_wait" do
    it "captures and waits for completion" do
      stub_request(:post, "https://api.stack0.io/webdata/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "ss_123", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.io/webdata/screenshots/ss_123")
        .to_return(
          status: 200,
          body: {
            "id" => "ss_123",
            "status" => "completed",
            "imageUrl" => "https://cdn.stack0.io/abc.png",
            "createdAt" => "2024-01-15T10:00:00Z",
            "completedAt" => "2024-01-15T10:00:05Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = webdata.screenshot_and_wait(url: "https://example.com", poll_interval: 0.1, timeout: 5)

      expect(result["status"]).to eq("completed")
      expect(result["imageUrl"]).to include("cdn.stack0.io")
    end

    it "raises error on failure" do
      stub_request(:post, "https://api.stack0.io/webdata/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "ss_fail", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.io/webdata/screenshots/ss_fail")
        .to_return(
          status: 200,
          body: { "id" => "ss_fail", "status" => "failed", "error" => "URL not reachable" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        webdata.screenshot_and_wait(url: "https://unreachable.example.com", poll_interval: 0.1, timeout: 5)
      end.to raise_error(Stack0::Error, "URL not reachable")
    end

    it "raises timeout error" do
      stub_request(:post, "https://api.stack0.io/webdata/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "ss_slow", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.io/webdata/screenshots/ss_slow")
        .to_return(
          status: 200,
          body: { "id" => "ss_slow", "status" => "processing" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        webdata.screenshot_and_wait(url: "https://slow.example.com", poll_interval: 0.05, timeout: 0.1)
      end.to raise_error(Stack0::TimeoutError)
    end
  end

  describe "#extract" do
    it "creates an extraction job" do
      stub_stack0_request(:post, "/webdata/extractions", response_body: {
        "id" => "ext_123",
        "status" => "pending",
        "url" => "https://example.com/article"
      })

      result = webdata.extract(url: "https://example.com/article")

      expect(result["id"]).to eq("ext_123")
      expect(result["status"]).to eq("pending")
    end

    it "creates an extraction with options" do
      stub_stack0_request(:post, "/webdata/extractions", response_body: {
        "id" => "ext_456",
        "status" => "pending"
      })

      result = webdata.extract(
        url: "https://example.com/article",
        mode: "markdown",
        include_metadata: true
      )

      expect(result["id"]).to eq("ext_456")
    end
  end

  describe "#get_extraction" do
    it "retrieves an extraction by ID" do
      stub_stack0_request(:get, "/webdata/extractions/ext_123", response_body: {
        "id" => "ext_123",
        "status" => "completed",
        "content" => "# Article Title\n\nContent here...",
        "metadata" => { "title" => "Article Title" },
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:00:05Z"
      })

      result = webdata.get_extraction(id: "ext_123")

      expect(result["id"]).to eq("ext_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#list_extractions" do
    it "lists extractions" do
      stub_stack0_request(:get, "/webdata/extractions", response_body: {
        "items" => [
          { "id" => "ext_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => nil
      })

      result = webdata.list_extractions

      expect(result["items"].length).to eq(1)
    end
  end

  describe "#extract_and_wait" do
    it "extracts and waits for completion" do
      stub_request(:post, "https://api.stack0.io/webdata/extractions")
        .to_return(
          status: 200,
          body: { "id" => "ext_123", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.io/webdata/extractions/ext_123")
        .to_return(
          status: 200,
          body: {
            "id" => "ext_123",
            "status" => "completed",
            "content" => "# Title\n\nContent",
            "createdAt" => "2024-01-15T10:00:00Z",
            "completedAt" => "2024-01-15T10:00:05Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = webdata.extract_and_wait(url: "https://example.com/article", poll_interval: 0.1, timeout: 5)

      expect(result["status"]).to eq("completed")
      expect(result["content"]).to include("Title")
    end
  end

  describe "#create_schedule" do
    it "creates a scheduled job" do
      stub_stack0_request(:post, "/webdata/schedules", response_body: {
        "id" => "sched_123",
        "name" => "Daily Screenshot",
        "type" => "screenshot",
        "frequency" => "daily",
        "isActive" => true
      })

      result = webdata.create_schedule(
        name: "Daily Screenshot",
        url: "https://example.com",
        type: "screenshot",
        frequency: "daily"
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
        "lastRunAt" => "2024-01-15T10:00:00Z",
        "nextRunAt" => "2024-01-16T10:00:00Z"
      })

      result = webdata.get_schedule(id: "sched_123")

      expect(result["createdAt"]).to be_a(Time)
      expect(result["nextRunAt"]).to be_a(Time)
    end
  end

  describe "#list_schedules" do
    it "lists schedules" do
      stub_stack0_request(:get, "/webdata/schedules", response_body: {
        "items" => [
          { "id" => "sched_1", "name" => "Schedule 1", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => nil
      })

      result = webdata.list_schedules

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

      result = webdata.toggle_schedule(id: "sched_123")

      expect(result["isActive"]).to be(false)
    end
  end

  describe "#delete_schedule" do
    it "deletes a schedule" do
      stub_stack0_request(:delete, "/webdata/schedules/sched_123", response_body: {
        "success" => true
      })

      result = webdata.delete_schedule(id: "sched_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#get_usage" do
    it "retrieves usage statistics" do
      stub_stack0_request(:get, "/webdata/usage", response_body: {
        "screenshotsTotal" => 500,
        "extractionsTotal" => 300,
        "periodStart" => "2024-01-01T00:00:00Z",
        "periodEnd" => "2024-01-31T23:59:59Z"
      })

      result = webdata.get_usage

      expect(result["screenshotsTotal"]).to eq(500)
      expect(result["periodStart"]).to be_a(Time)
    end
  end

  describe "#batch_screenshots" do
    it "creates a batch screenshot job" do
      stub_stack0_request(:post, "/webdata/batch/screenshots", response_body: {
        "id" => "batch_123",
        "type" => "screenshot",
        "totalUrls" => 5,
        "status" => "pending"
      })

      result = webdata.batch_screenshots(
        urls: %w[
          https://example1.com
          https://example2.com
          https://example3.com
          https://example4.com
          https://example5.com
        ]
      )

      expect(result["id"]).to eq("batch_123")
      expect(result["totalUrls"]).to eq(5)
    end
  end

  describe "#batch_extractions" do
    it "creates a batch extraction job" do
      stub_stack0_request(:post, "/webdata/batch/extractions", response_body: {
        "id" => "batch_456",
        "type" => "extraction",
        "totalUrls" => 3,
        "status" => "pending"
      })

      result = webdata.batch_extractions(
        urls: %w[
          https://example1.com/article
          https://example2.com/article
          https://example3.com/article
        ]
      )

      expect(result["id"]).to eq("batch_456")
    end
  end

  describe "#get_batch_job" do
    it "retrieves a batch job by ID" do
      stub_stack0_request(:get, "/webdata/batch/batch_123", response_body: {
        "id" => "batch_123",
        "status" => "completed",
        "totalUrls" => 5,
        "completedUrls" => 5,
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:05:00Z"
      })

      result = webdata.get_batch_job(id: "batch_123")

      expect(result["completedUrls"]).to eq(5)
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#batch_screenshots_and_wait" do
    it "creates batch and waits for completion" do
      stub_request(:post, "https://api.stack0.io/webdata/batch/screenshots")
        .to_return(
          status: 200,
          body: { "id" => "batch_123", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.io/webdata/batch/batch_123")
        .to_return(
          status: 200,
          body: {
            "id" => "batch_123",
            "status" => "completed",
            "totalUrls" => 2,
            "completedUrls" => 2,
            "createdAt" => "2024-01-15T10:00:00Z",
            "completedAt" => "2024-01-15T10:05:00Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = webdata.batch_screenshots_and_wait(
        urls: %w[https://example1.com https://example2.com],
        poll_interval: 0.1,
        timeout: 5
      )

      expect(result["status"]).to eq("completed")
    end
  end
end
