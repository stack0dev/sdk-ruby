# frozen_string_literal: true

RSpec.describe Stack0::Extraction::Client do
  let(:client) { test_client }
  let(:extraction) { client.extraction }

  describe "#extract" do
    it "creates an extraction job" do
      stub_stack0_request(:post, "/webdata/extractions", response_body: {
        "id" => "extraction_123",
        "status" => "pending"
      })

      result = extraction.extract(url: "https://example.com/article")

      expect(result["id"]).to eq("extraction_123")
      expect(result["status"]).to eq("pending")
    end

    it "accepts extraction options" do
      stub_stack0_request(:post, "/webdata/extractions", response_body: {
        "id" => "extraction_456",
        "status" => "pending"
      })

      result = extraction.extract(
        url: "https://example.com/article",
        mode: "markdown",
        include_images: true,
        include_links: true,
        include_metadata: true
      )

      expect(result["id"]).to eq("extraction_456")
    end

    it "accepts schema for structured extraction" do
      stub_stack0_request(:post, "/webdata/extractions", response_body: {
        "id" => "extraction_789",
        "status" => "pending"
      })

      result = extraction.extract(
        url: "https://example.com/product",
        mode: "schema",
        schema: {
          "name" => { "type" => "string" },
          "price" => { "type" => "number" },
          "description" => { "type" => "string" }
        }
      )

      expect(result["id"]).to eq("extraction_789")
    end
  end

  describe "#get" do
    it "retrieves an extraction by ID" do
      stub_stack0_request(:get, "/webdata/extractions/extraction_123", response_body: {
        "id" => "extraction_123",
        "status" => "completed",
        "content" => "# Article Title\n\nContent here...",
        "metadata" => { "title" => "Article Title", "author" => "John Doe" },
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:00:05Z"
      })

      result = extraction.get(id: "extraction_123")

      expect(result["id"]).to eq("extraction_123")
      expect(result["status"]).to eq("completed")
      expect(result["content"]).to include("Article Title")
      expect(result["createdAt"]).to be_a(Time)
      expect(result["completedAt"]).to be_a(Time)
    end
  end

  describe "#list" do
    it "lists extractions with filters" do
      stub_stack0_request(:get, "/webdata/extractions?status=completed&limit=20", response_body: {
        "items" => [
          { "id" => "extraction_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" },
          { "id" => "extraction_2", "status" => "completed", "createdAt" => "2024-01-15T11:00:00Z" }
        ],
        "cursor" => nil
      })

      result = extraction.list(status: "completed", limit: 20)

      expect(result["items"].length).to eq(2)
      expect(result["items"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#delete" do
    it "deletes an extraction" do
      stub_request(:delete, "https://api.stack0.dev/webdata/extractions/extraction_123")
        .with(body: { "id" => "extraction_123" }.to_json)
        .to_return(
          status: 200,
          body: { "success" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = extraction.delete(id: "extraction_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#batch" do
    it "creates batch extraction jobs" do
      stub_stack0_request(:post, "/webdata/batch/extractions", response_body: {
        "id" => "batch_123",
        "totalUrls" => 3,
        "status" => "pending"
      })

      result = extraction.batch(urls: [
        "https://example1.com/article",
        "https://example2.com/article",
        "https://example3.com/article"
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

      result = extraction.get_batch_job(id: "batch_123")

      expect(result["status"]).to eq("completed")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#list_batch_jobs" do
    it "lists batch jobs" do
      stub_stack0_request(:get, "/webdata/batch?type=extraction", response_body: {
        "items" => [
          { "id" => "batch_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => nil
      })

      result = extraction.list_batch_jobs

      expect(result["items"].length).to eq(1)
    end
  end

  describe "#cancel_batch_job" do
    it "cancels a batch job" do
      stub_stack0_request(:post, "/webdata/batch/batch_123/cancel", response_body: {
        "success" => true
      })

      result = extraction.cancel_batch_job(id: "batch_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#extract_and_wait" do
    it "extracts and waits for completion" do
      stub_request(:post, "https://api.stack0.dev/webdata/extractions")
        .to_return(
          status: 200,
          body: { "id" => "extraction_123", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/extractions/extraction_123")
        .to_return(
          status: 200,
          body: {
            "id" => "extraction_123",
            "status" => "completed",
            "content" => "# Article\n\nContent...",
            "createdAt" => "2024-01-15T10:00:00Z",
            "completedAt" => "2024-01-15T10:00:05Z"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = extraction.extract_and_wait(
        url: "https://example.com/article",
        poll_interval: 0.1,
        timeout: 5
      )

      expect(result["status"]).to eq("completed")
      expect(result["content"]).to include("Article")
    end

    it "raises error on failure" do
      stub_request(:post, "https://api.stack0.dev/webdata/extractions")
        .to_return(
          status: 200,
          body: { "id" => "extraction_fail", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/extractions/extraction_fail")
        .to_return(
          status: 200,
          body: { "id" => "extraction_fail", "status" => "failed", "error" => "Content not extractable" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        extraction.extract_and_wait(url: "https://example.com/binary", poll_interval: 0.1, timeout: 5)
      end.to raise_error(Stack0::Error, "Content not extractable")
    end

    it "raises timeout error" do
      stub_request(:post, "https://api.stack0.dev/webdata/extractions")
        .to_return(
          status: 200,
          body: { "id" => "extraction_slow", "status" => "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      stub_request(:get, "https://api.stack0.dev/webdata/extractions/extraction_slow")
        .to_return(
          status: 200,
          body: { "id" => "extraction_slow", "status" => "processing" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        extraction.extract_and_wait(url: "https://slow.example.com/article", poll_interval: 0.05, timeout: 0.1)
      end.to raise_error(Stack0::TimeoutError)
    end
  end

  describe "#batch_and_wait" do
    it "creates batch and waits for completion" do
      stub_request(:post, "https://api.stack0.dev/webdata/batch/extractions")
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

      result = extraction.batch_and_wait(
        urls: %w[https://example1.com/article https://example2.com/article],
        poll_interval: 0.1,
        timeout: 5
      )

      expect(result["status"]).to eq("completed")
    end
  end

  describe "#create_schedule" do
    it "creates a scheduled extraction job" do
      stub_stack0_request(:post, "/webdata/schedules", response_body: {
        "id" => "sched_123",
        "name" => "Daily Extraction",
        "type" => "extraction",
        "frequency" => "daily",
        "isActive" => true
      })

      result = extraction.create_schedule(
        name: "Daily Extraction",
        url: "https://example.com/article",
        config: { mode: "markdown", include_metadata: true }
      )

      expect(result["id"]).to eq("sched_123")
    end
  end

  describe "#get_schedule" do
    it "retrieves a schedule by ID" do
      stub_stack0_request(:get, "/webdata/schedules/sched_123", response_body: {
        "id" => "sched_123",
        "name" => "Daily Extraction",
        "createdAt" => "2024-01-15T10:00:00Z",
        "nextRunAt" => "2024-01-16T10:00:00Z"
      })

      result = extraction.get_schedule(id: "sched_123")

      expect(result["createdAt"]).to be_a(Time)
      expect(result["nextRunAt"]).to be_a(Time)
    end
  end

  describe "#list_schedules" do
    it "lists schedules" do
      stub_stack0_request(:get, "/webdata/schedules?type=extraction", response_body: {
        "items" => [
          { "id" => "sched_1", "name" => "Schedule 1", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "cursor" => nil
      })

      result = extraction.list_schedules

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

      result = extraction.toggle_schedule(id: "sched_123")

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

      result = extraction.delete_schedule(id: "sched_123")

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

      result = extraction.get_usage

      expect(result["extractionsTotal"]).to eq(300)
      expect(result["periodStart"]).to be_a(Time)
    end
  end

  describe "#get_usage_daily" do
    it "retrieves daily usage breakdown" do
      stub_stack0_request(:get, "/webdata/usage/daily", response_body: {
        "data" => [
          { "date" => "2024-01-15", "screenshots" => 50, "extractions" => 30 },
          { "date" => "2024-01-16", "screenshots" => 45, "extractions" => 25 }
        ]
      })

      result = extraction.get_usage_daily

      expect(result["data"].length).to eq(2)
    end
  end
end
