# frozen_string_literal: true

module Stack0
  # Base error class for all Stack0 errors
  class Error < StandardError; end

  # API error with status code and response details
  class APIError < Error
    attr_reader :status_code, :code, :response

    def initialize(message, status_code:, code: nil, response: nil)
      super(message)
      @status_code = status_code
      @code = code
      @response = response
    end
  end

  # Authentication failed (401)
  class AuthenticationError < APIError; end

  # Rate limit exceeded (429)
  class RateLimitError < APIError; end

  # Resource not found (404)
  class NotFoundError < APIError; end

  # Validation error (422)
  class ValidationError < APIError; end

  # Operation timed out
  class TimeoutError < Error; end
end
