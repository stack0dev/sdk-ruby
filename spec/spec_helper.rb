# frozen_string_literal: true

require "webmock/rspec"
require "vcr"
require "stack0"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<API_KEY>") { ENV.fetch("STACK0_API_KEY", "test_api_key") }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before do
    Stack0.instance_variable_set(:@configuration, nil)
  end
end

# Helper to create a test client
def test_client(api_key: "test_api_key")
  Stack0::Client.new(api_key: api_key)
end

# Helper to stub API requests
def stub_stack0_request(method, path, response_body: {}, status: 200)
  stub_request(method, "https://api.stack0.io#{path}")
    .to_return(
      status: status,
      body: response_body.to_json,
      headers: { "Content-Type" => "application/json" }
    )
end
