# frozen_string_literal: true

RSpec.describe Stack0::Error do
  it "inherits from StandardError" do
    expect(Stack0::Error).to be < StandardError
  end

  it "can be raised with a message" do
    expect { raise Stack0::Error, "Something went wrong" }
      .to raise_error(Stack0::Error, "Something went wrong")
  end
end

RSpec.describe Stack0::APIError do
  subject(:error) do
    described_class.new(
      "Not Found",
      status_code: 404,
      code: "RESOURCE_NOT_FOUND",
      response: { "error" => "Not Found" }
    )
  end

  it "inherits from Stack0::Error" do
    expect(described_class).to be < Stack0::Error
  end

  it "stores the status code" do
    expect(error.status_code).to eq(404)
  end

  it "stores the error code" do
    expect(error.code).to eq("RESOURCE_NOT_FOUND")
  end

  it "stores the response body" do
    expect(error.response).to eq({ "error" => "Not Found" })
  end

  it "stores the message" do
    expect(error.message).to eq("Not Found")
  end
end

RSpec.describe Stack0::AuthenticationError do
  it "inherits from APIError" do
    expect(described_class).to be < Stack0::APIError
  end

  it "can be raised with authentication error details" do
    error = described_class.new("Invalid API key", status_code: 401)
    expect(error.status_code).to eq(401)
    expect(error.message).to eq("Invalid API key")
  end
end

RSpec.describe Stack0::RateLimitError do
  it "inherits from APIError" do
    expect(described_class).to be < Stack0::APIError
  end

  it "can be raised with rate limit details" do
    error = described_class.new("Rate limit exceeded", status_code: 429, code: "RATE_LIMITED")
    expect(error.status_code).to eq(429)
    expect(error.code).to eq("RATE_LIMITED")
  end
end

RSpec.describe Stack0::NotFoundError do
  it "inherits from APIError" do
    expect(described_class).to be < Stack0::APIError
  end

  it "can be raised with not found details" do
    error = described_class.new("Resource not found", status_code: 404)
    expect(error.status_code).to eq(404)
  end
end

RSpec.describe Stack0::ValidationError do
  it "inherits from APIError" do
    expect(described_class).to be < Stack0::APIError
  end

  it "can be raised with validation details" do
    error = described_class.new(
      "Validation failed",
      status_code: 422,
      response: { "errors" => { "email" => "is invalid" } }
    )
    expect(error.status_code).to eq(422)
    expect(error.response["errors"]["email"]).to eq("is invalid")
  end
end

RSpec.describe Stack0::TimeoutError do
  it "inherits from Stack0::Error" do
    expect(described_class).to be < Stack0::Error
  end

  it "can be raised with a timeout message" do
    expect { raise Stack0::TimeoutError, "Operation timed out after 60 seconds" }
      .to raise_error(Stack0::TimeoutError, "Operation timed out after 60 seconds")
  end
end
