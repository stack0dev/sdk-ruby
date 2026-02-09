# frozen_string_literal: true

RSpec.describe Stack0::HTTPClient do
  let(:api_key) { "test_api_key" }
  let(:base_url) { "https://api.stack0.dev/v1" }
  let(:client) { described_class.new(api_key: api_key, base_url: base_url, timeout: 30) }

  describe "#initialize" do
    it "creates a client with required parameters" do
      expect(client).to be_a(described_class)
    end

    it "uses default base_url if not provided" do
      default_client = described_class.new(api_key: api_key)
      expect(default_client).to be_a(described_class)
    end

    it "uses default timeout if not provided" do
      default_client = described_class.new(api_key: api_key)
      expect(default_client).to be_a(described_class)
    end
  end

  describe "#get" do
    it "makes a GET request and returns parsed JSON" do
      stub_request(:get, "#{base_url}/test")
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
        .to_return(
          status: 200,
          body: { "data" => "value" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.get("/test")
      expect(result).to eq({ "data" => "value" })
    end

    it "raises NotFoundError for 404 responses" do
      stub_request(:get, "#{base_url}/not-found")
        .to_return(
          status: 404,
          body: { "message" => "Resource not found" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get("/not-found") }
        .to raise_error(Stack0::NotFoundError) do |error|
          expect(error.status_code).to eq(404)
          expect(error.message).to eq("Resource not found")
        end
    end

    it "raises AuthenticationError for 401 responses" do
      stub_request(:get, "#{base_url}/protected")
        .to_return(
          status: 401,
          body: { "message" => "Invalid API key" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get("/protected") }
        .to raise_error(Stack0::AuthenticationError) do |error|
          expect(error.status_code).to eq(401)
          expect(error.message).to eq("Invalid API key")
        end
    end

    it "raises RateLimitError for 429 responses" do
      stub_request(:get, "#{base_url}/rate-limited")
        .to_return(
          status: 429,
          body: { "message" => "Rate limit exceeded", "code" => "RATE_LIMITED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get("/rate-limited") }
        .to raise_error(Stack0::RateLimitError) do |error|
          expect(error.status_code).to eq(429)
          expect(error.code).to eq("RATE_LIMITED")
        end
    end

    it "raises ValidationError for 422 responses" do
      stub_request(:get, "#{base_url}/invalid")
        .to_return(
          status: 422,
          body: { "message" => "Validation failed", "errors" => { "email" => "invalid" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get("/invalid") }
        .to raise_error(Stack0::ValidationError) do |error|
          expect(error.status_code).to eq(422)
          expect(error.response["errors"]["email"]).to eq("invalid")
        end
    end

    it "raises APIError for other error responses" do
      stub_request(:get, "#{base_url}/error")
        .to_return(
          status: 500,
          body: { "message" => "Internal server error" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get("/error") }
        .to raise_error(Stack0::APIError) do |error|
          expect(error.status_code).to eq(500)
          expect(error.message).to eq("Internal server error")
        end
    end

    it "handles non-JSON error responses" do
      stub_request(:get, "#{base_url}/html-error")
        .to_return(
          status: 502,
          body: "<html>Bad Gateway</html>",
          headers: { "Content-Type" => "text/html" }
        )

      expect { client.get("/html-error") }
        .to raise_error(Stack0::APIError) do |error|
          expect(error.status_code).to eq(502)
        end
    end

    it "handles empty error responses" do
      stub_request(:get, "#{base_url}/empty-error")
        .to_return(status: 503, body: "", headers: {})

      expect { client.get("/empty-error") }
        .to raise_error(Stack0::APIError) do |error|
          expect(error.status_code).to eq(503)
        end
    end
  end

  describe "#post" do
    it "makes a POST request with JSON body" do
      stub_request(:post, "#{base_url}/create")
        .with(
          body: { "name" => "test" }.to_json,
          headers: {
            "Authorization" => "Bearer #{api_key}",
            "Content-Type" => "application/json"
          }
        )
        .to_return(
          status: 201,
          body: { "id" => "123", "name" => "test" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.post("/create", { "name" => "test" })
      expect(result).to eq({ "id" => "123", "name" => "test" })
    end

    it "makes a POST request without body" do
      stub_request(:post, "#{base_url}/trigger")
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
        .to_return(
          status: 200,
          body: { "success" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.post("/trigger")
      expect(result).to eq({ "success" => true })
    end

    it "raises errors for failed POST requests" do
      stub_request(:post, "#{base_url}/fail")
        .to_return(
          status: 400,
          body: { "message" => "Bad request" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.post("/fail", {}) }
        .to raise_error(Stack0::APIError) do |error|
          expect(error.status_code).to eq(400)
        end
    end
  end

  describe "#put" do
    it "makes a PUT request with JSON body" do
      stub_request(:put, "#{base_url}/update/123")
        .with(
          body: { "name" => "updated" }.to_json,
          headers: { "Authorization" => "Bearer #{api_key}" }
        )
        .to_return(
          status: 200,
          body: { "id" => "123", "name" => "updated" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.put("/update/123", { "name" => "updated" })
      expect(result).to eq({ "id" => "123", "name" => "updated" })
    end
  end

  describe "#patch" do
    it "makes a PATCH request with JSON body" do
      stub_request(:patch, "#{base_url}/patch/123")
        .with(
          body: { "status" => "active" }.to_json,
          headers: { "Authorization" => "Bearer #{api_key}" }
        )
        .to_return(
          status: 200,
          body: { "id" => "123", "status" => "active" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.patch("/patch/123", { "status" => "active" })
      expect(result).to eq({ "id" => "123", "status" => "active" })
    end
  end

  describe "#delete" do
    it "makes a DELETE request" do
      stub_request(:delete, "#{base_url}/delete/123")
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
        .to_return(
          status: 200,
          body: { "success" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.delete("/delete/123")
      expect(result).to eq({ "success" => true })
    end
  end

  describe "#delete_with_body" do
    it "makes a DELETE request with a body" do
      stub_request(:delete, "#{base_url}/delete/bulk")
        .with(
          body: { "ids" => %w[1 2 3] }.to_json,
          headers: { "Authorization" => "Bearer #{api_key}" }
        )
        .to_return(
          status: 200,
          body: { "deleted" => 3 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.delete_with_body("/delete/bulk", { "ids" => %w[1 2 3] })
      expect(result).to eq({ "deleted" => 3 })
    end
  end

  describe "request headers" do
    it "includes Authorization header with Bearer token" do
      stub_request(:get, "#{base_url}/auth-test")
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
        .to_return(status: 200, body: "{}".to_json, headers: { "Content-Type" => "application/json" })

      client.get("/auth-test")
      expect(WebMock).to have_requested(:get, "#{base_url}/auth-test")
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
    end

    it "includes Content-Type header" do
      stub_request(:post, "#{base_url}/content-test")
        .with(headers: { "Content-Type" => "application/json" })
        .to_return(status: 200, body: "{}".to_json, headers: { "Content-Type" => "application/json" })

      client.post("/content-test", {})
      expect(WebMock).to have_requested(:post, "#{base_url}/content-test")
        .with(headers: { "Content-Type" => "application/json" })
    end

    it "includes Accept header" do
      stub_request(:get, "#{base_url}/accept-test")
        .with(headers: { "Accept" => "application/json" })
        .to_return(status: 200, body: "{}".to_json, headers: { "Content-Type" => "application/json" })

      client.get("/accept-test")
      expect(WebMock).to have_requested(:get, "#{base_url}/accept-test")
        .with(headers: { "Accept" => "application/json" })
    end
  end
end
