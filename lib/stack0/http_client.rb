# frozen_string_literal: true

require "faraday"
require "json"

module Stack0
  # HTTP client for Stack0 API
  # Handles authentication, request/response formatting, and error handling
  class HTTPClient
    def initialize(api_key:, base_url: "https://api.stack0.dev/v1", timeout: 30)
      @api_key = api_key
      @base_url = base_url
      @timeout = timeout
      @connection = build_connection
    end

    def get(path)
      handle_response(@connection.get(path))
    end

    def post(path, body = nil)
      handle_response(@connection.post(path) do |req|
        req.body = body.to_json if body
      end)
    end

    def put(path, body)
      handle_response(@connection.put(path) do |req|
        req.body = body.to_json
      end)
    end

    def patch(path, body)
      handle_response(@connection.patch(path) do |req|
        req.body = body.to_json
      end)
    end

    def delete(path)
      handle_response(@connection.delete(path))
    end

    def delete_with_body(path, body)
      handle_response(@connection.delete(path) do |req|
        req.body = body.to_json
      end)
    end

    private

    def build_connection
      Faraday.new(url: @base_url) do |conn|
        conn.headers["Authorization"] = "Bearer #{@api_key}"
        conn.headers["Content-Type"] = "application/json"
        conn.headers["Accept"] = "application/json"
        conn.options.timeout = @timeout
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      return response.body if response.success?

      error_body = parse_error_body(response)
      message = error_body["message"] || "HTTP #{response.status}"
      code = error_body["code"]

      error_class = case response.status
                    when 401 then AuthenticationError
                    when 404 then NotFoundError
                    when 422 then ValidationError
                    when 429 then RateLimitError
                    else APIError
                    end

      raise error_class.new(message, status_code: response.status, code: code, response: error_body)
    end

    def parse_error_body(response)
      if response.body.is_a?(Hash)
        response.body
      elsif response.body.is_a?(String) && !response.body.empty?
        JSON.parse(response.body)
      else
        { "message" => response.reason_phrase || "Unknown error" }
      end
    rescue JSON::ParserError
      { "message" => response.body.to_s }
    end
  end
end
