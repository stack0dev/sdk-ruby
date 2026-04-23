# frozen_string_literal: true

require_relative "configuration"
require_relative "http_client"
require_relative "mail/client"
require_relative "cdn/client"
require_relative "screenshots/client"
require_relative "extraction/client"
require_relative "integrations/client"
require_relative "marketing/client"
require_relative "webdata/client"

module Stack0
  # Main Stack0 SDK client
  #
  # @example Basic usage
  #   client = Stack0::Client.new(api_key: "stack0_...")
  #
  #   # Send an email
  #   client.mail.send(
  #     from: "hello@example.com",
  #     to: "user@example.com",
  #     subject: "Hello",
  #     html: "<p>Hello World</p>"
  #   )
  #
  #   # Upload to CDN
  #   client.cdn.upload_from_url(url: "https://example.com/image.png")
  #
  #   # Take a screenshot
  #   screenshot = client.screenshots.capture_and_wait(url: "https://example.com")
  #
  class Client
    attr_reader :mail, :cdn, :screenshots, :extraction, :integrations, :marketing, :webdata

    # Initialize a new Stack0 client
    #
    # @param api_key [String] Your Stack0 API key
    # @param base_url [String, nil] Base URL for API requests (default: https://api.stack0.dev/v1)
    # @param cdn_url [String, nil] CDN URL for uploads (default: https://cdn.stack0.dev)
    # @param timeout [Integer, nil] Request timeout in seconds (default: 30)
    def initialize(api_key:, base_url: nil, cdn_url: nil, timeout: nil)
      actual_base_url = base_url || "https://api.stack0.dev/v1"
      actual_cdn_url = cdn_url || "https://cdn.stack0.dev"
      actual_timeout = timeout || 30

      http = HTTPClient.new(
        api_key: api_key,
        base_url: actual_base_url,
        timeout: actual_timeout
      )

      @mail = Mail::Client.new(http)
      @cdn = CDN::Client.new(http, actual_cdn_url)
      @screenshots = Screenshots::Client.new(http)
      @extraction = Extraction::Client.new(http)
      @integrations = Integrations::Client.new(http)
      @marketing = Marketing::Client.new(http)
      @webdata = Webdata::Client.new(http)
    end
  end
end
