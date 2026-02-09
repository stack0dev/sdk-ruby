# frozen_string_literal: true

RSpec.describe Stack0::Polling do
  let(:test_class) do
    Class.new do
      include Stack0::Polling
    end
  end

  let(:instance) { test_class.new }

  describe "#poll_until_complete" do
    it "returns immediately when status is completed" do
      call_count = 0
      get_method = lambda do |id|
        call_count += 1
        { "id" => id, "status" => "completed", "data" => "result" }
      end

      result = instance.poll_until_complete(
        initial_id: "test_123",
        get_method: get_method,
        completed_statuses: ["completed"],
        poll_interval: 0.01,
        timeout: 1
      )

      expect(result["status"]).to eq("completed")
      expect(result["data"]).to eq("result")
      expect(call_count).to eq(1)
    end

    it "polls until completion" do
      call_count = 0
      get_method = lambda do |id|
        call_count += 1
        status = call_count >= 3 ? "completed" : "processing"
        { "id" => id, "status" => status }
      end

      result = instance.poll_until_complete(
        initial_id: "test_123",
        get_method: get_method,
        completed_statuses: ["completed"],
        poll_interval: 0.01,
        timeout: 5
      )

      expect(result["status"]).to eq("completed")
      expect(call_count).to eq(3)
    end

    it "supports multiple completed statuses" do
      get_method = lambda do |id|
        { "id" => id, "status" => "done" }
      end

      result = instance.poll_until_complete(
        initial_id: "test_123",
        get_method: get_method,
        completed_statuses: %w[completed done finished],
        poll_interval: 0.01,
        timeout: 1
      )

      expect(result["status"]).to eq("done")
    end

    it "raises Error when status is failed" do
      get_method = lambda do |_id|
        { "status" => "failed", "error" => "Processing error occurred" }
      end

      expect do
        instance.poll_until_complete(
          initial_id: "test_123",
          get_method: get_method,
          completed_statuses: ["completed"],
          failed_statuses: ["failed"],
          poll_interval: 0.01,
          timeout: 1
        )
      end.to raise_error(Stack0::Error, "Processing error occurred")
    end

    it "raises Error with default message when no error field" do
      get_method = lambda do |_id|
        { "status" => "failed" }
      end

      expect do
        instance.poll_until_complete(
          initial_id: "test_123",
          get_method: get_method,
          completed_statuses: ["completed"],
          failed_statuses: ["failed"],
          poll_interval: 0.01,
          timeout: 1
        )
      end.to raise_error(Stack0::Error, "Operation failed")
    end

    it "supports symbol keys for status" do
      get_method = lambda do |_id|
        { id: "test_123", status: "completed" }
      end

      result = instance.poll_until_complete(
        initial_id: "test_123",
        get_method: get_method,
        completed_statuses: ["completed"],
        poll_interval: 0.01,
        timeout: 1
      )

      expect(result[:status]).to eq("completed")
    end

    it "supports symbol keys for error" do
      get_method = lambda do |_id|
        { status: "failed", error: "Symbol error message" }
      end

      expect do
        instance.poll_until_complete(
          initial_id: "test_123",
          get_method: get_method,
          completed_statuses: ["completed"],
          failed_statuses: ["failed"],
          poll_interval: 0.01,
          timeout: 1
        )
      end.to raise_error(Stack0::Error, "Symbol error message")
    end

    it "raises TimeoutError when timeout is exceeded" do
      call_count = 0
      get_method = lambda do |id|
        call_count += 1
        { "id" => id, "status" => "processing" }
      end

      expect do
        instance.poll_until_complete(
          initial_id: "test_123",
          get_method: get_method,
          completed_statuses: ["completed"],
          poll_interval: 0.05,
          timeout: 0.1
        )
      end.to raise_error(Stack0::TimeoutError, /timed out after 0.1 seconds/)

      expect(call_count).to be >= 1
    end

    it "uses default failed_statuses" do
      get_method = lambda do |_id|
        { "status" => "failed", "error" => "Default failure" }
      end

      expect do
        instance.poll_until_complete(
          initial_id: "test_123",
          get_method: get_method,
          completed_statuses: ["completed"],
          poll_interval: 0.01,
          timeout: 1
        )
      end.to raise_error(Stack0::Error, "Default failure")
    end

    it "passes the ID to the get_method" do
      received_id = nil
      get_method = lambda do |id|
        received_id = id
        { "status" => "completed" }
      end

      instance.poll_until_complete(
        initial_id: "my_unique_id",
        get_method: get_method,
        completed_statuses: ["completed"],
        poll_interval: 0.01,
        timeout: 1
      )

      expect(received_id).to eq("my_unique_id")
    end
  end
end
