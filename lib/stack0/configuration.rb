# frozen_string_literal: true

module Stack0
  # Configuration class for Stack0 SDK
  # Holds API key, base URL, and other settings
  class Configuration
    attr_accessor :api_key, :base_url, :cdn_url, :timeout

    def initialize
      @base_url = "https://api.stack0.dev/v1"
      @cdn_url = nil
      @timeout = 30
    end
  end
end
