# frozen_string_literal: true

require_relative "stack0/version"
require_relative "stack0/errors"
require_relative "stack0/configuration"
require_relative "stack0/http_client"
require_relative "stack0/polling"
require_relative "stack0/client"

# Stack0 Ruby SDK
#
# @example Quick start
#   require "stack0"
#
#   client = Stack0::Client.new(api_key: ENV["STACK0_API_KEY"])
#
#   # Send an email
#   client.mail.send(
#     from: "hello@example.com",
#     to: "user@example.com",
#     subject: "Hello from Stack0",
#     html: "<h1>Welcome!</h1>"
#   )
#
#   # Upload to CDN
#   asset = client.cdn.upload_from_url(url: "https://example.com/image.png")
#   puts asset["url"]
#
#   # Capture a screenshot
#   screenshot = client.screenshots.capture_and_wait(url: "https://example.com")
#   puts screenshot["imageUrl"]
#
#   # Extract content from a webpage
#   extraction = client.extraction.extract_and_wait(url: "https://example.com/article")
#   puts extraction["markdown"]
#
module Stack0
  class << self
    # Configure the SDK globally
    #
    # @yield [config] Configuration block
    # @yieldparam config [Configuration] The configuration instance
    #
    # @example
    #   Stack0.configure do |config|
    #     config.api_key = "stack0_..."
    #     config.timeout = 60
    #   end
    def configure
      yield(configuration)
    end

    # Get the global configuration
    #
    # @return [Configuration] The global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Create a new client with the global configuration
    #
    # @return [Client] A new client instance
    def client
      Client.new(
        api_key: configuration.api_key,
        base_url: configuration.base_url,
        cdn_url: configuration.cdn_url,
        timeout: configuration.timeout
      )
    end
  end
end
