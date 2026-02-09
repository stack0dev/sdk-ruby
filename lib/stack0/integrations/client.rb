# frozen_string_literal: true

require "time"
require "uri"

require_relative "crm"
require_relative "storage"
require_relative "communication"
require_relative "productivity"

module Stack0
  module Integrations
    # Main Integrations client for third-party integrations
    class Client
      attr_reader :crm, :storage, :communication, :productivity

      def initialize(http)
        @http = http
        @crm = CRM.new(http)
        @storage = Storage.new(http)
        @communication = Communication.new(http)
        @productivity = Productivity.new(http)
      end

      # List all available connectors
      #
      # @param category [String, nil] Filter by category
      # @return [Array<Hash>] List of connectors
      def list_connectors(category: nil)
        params = category ? "?category=#{category}" : ""
        @http.get("/integrations/connectors#{params}")
      end

      # Get a specific connector
      #
      # @param slug [String] Connector slug
      # @return [Hash] Connector details
      def get_connector(slug)
        @http.get("/integrations/connectors/#{slug}")
      end

      # List all connections
      #
      # @param project_id [String, nil] Project ID filter
      # @param environment [String, nil] Environment filter
      # @param connector_slug [String, nil] Connector slug filter
      # @param status [String, nil] Status filter
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] List of connections
      def list_connections(project_id: nil, environment: nil, connector_slug: nil, status: nil, limit: nil)
        params = {}
        params[:projectId] = project_id if project_id
        params[:environment] = environment if environment
        params[:connectorSlug] = connector_slug if connector_slug
        params[:status] = status if status
        params[:limit] = limit if limit

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/integrations/connections#{query}")
        response["connections"] = response["connections"].map { |c| convert_connection_dates(c) } if response["connections"]
        response
      end

      # Get a specific connection
      #
      # @param connection_id [String] Connection ID
      # @return [Hash] Connection details
      def get_connection(connection_id)
        response = @http.get("/integrations/connections/#{connection_id}")
        convert_connection_details_dates(response)
      end

      # Initiate OAuth flow for a connector
      #
      # @param connector_slug [String] Connector slug
      # @param redirect_url [String] Redirect URL after OAuth
      # @param name [String, nil] Connection name
      # @param project_id [String, nil] Project ID
      # @param environment [String, nil] Environment
      # @return [Hash] OAuth initiation response with auth_url, connection_id, state
      def initiate_oauth(connector_slug:, redirect_url:, name: nil, project_id: nil, environment: nil)
        body = { connectorSlug: connector_slug, redirectUrl: redirect_url }
        body[:name] = name if name
        body[:projectId] = project_id if project_id
        body[:environment] = environment if environment

        @http.post("/integrations/connections/oauth/initiate", body)
      end

      # Complete OAuth flow with callback data
      #
      # @param code [String] Authorization code from callback
      # @param state [String] State from initiate
      # @param redirect_url [String] Redirect URL (must match initiate)
      # @return [Hash] OAuth completion response
      def complete_oauth(code:, state:, redirect_url:)
        @http.post("/integrations/connections/oauth/callback", {
          code: code,
          state: state,
          redirectUrl: redirect_url
        })
      end

      # Update a connection
      #
      # @param connection_id [String] Connection ID
      # @param name [String, nil] Connection name
      # @param is_active [Boolean, nil] Whether connection is active
      # @return [Hash] Updated connection
      def update_connection(connection_id:, name: nil, is_active: nil)
        body = {}
        body[:name] = name if name
        body[:isActive] = is_active unless is_active.nil?

        @http.patch("/integrations/connections/#{connection_id}", body)
      end

      # Delete a connection
      #
      # @param connection_id [String] Connection ID
      # @return [Hash] Success response
      def delete_connection(connection_id)
        @http.delete("/integrations/connections/#{connection_id}")
      end

      # Reconnect an expired or errored connection
      #
      # @param connection_id [String] Connection ID
      # @param redirect_url [String] Redirect URL after OAuth
      # @return [Hash] Reconnection response with auth_url, state
      def reconnect_connection(connection_id:, redirect_url:)
        @http.post("/integrations/connections/#{connection_id}/reconnect", {
          redirectUrl: redirect_url
        })
      end

      # Get integration statistics
      #
      # @param environment [String, nil] Environment filter
      # @return [Hash] Integration statistics
      def get_stats(environment: nil)
        params = {}
        params[:environment] = environment if environment
        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/integrations/connections/stats#{query}")
      end

      # List API logs
      #
      # @param connection_id [String, nil] Connection ID filter
      # @param connector_slug [String, nil] Connector slug filter
      # @param status_code [Integer, nil] Status code filter
      # @param method [String, nil] HTTP method filter
      # @param search [String, nil] Search query
      # @param limit [Integer, nil] Maximum number of results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] List of logs
      def list_logs(connection_id: nil, connector_slug: nil, status_code: nil, method: nil,
                    search: nil, limit: nil, cursor: nil)
        params = {}
        params[:connectionId] = connection_id if connection_id
        params[:connectorSlug] = connector_slug if connector_slug
        params[:statusCode] = status_code if status_code
        params[:method] = method if method
        params[:search] = search if search
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/integrations/logs#{query}")
        response["logs"] = response["logs"].map { |l| convert_log_dates(l) } if response["logs"]
        response
      end

      # Make a raw passthrough request to the provider API
      #
      # @param connection_id [String] Connection ID
      # @param method [String] HTTP method
      # @param path [String] API path
      # @param body [Hash, nil] Request body
      # @param headers [Hash, nil] Request headers
      # @return [Hash] Provider response
      def passthrough(connection_id:, method:, path:, body: nil, headers: nil)
        request = {
          connectionId: connection_id,
          method: method,
          path: path
        }
        request[:body] = body if body
        request[:headers] = headers if headers

        @http.post("/integrations/passthrough", request)
      end

      private

      def convert_connection_dates(connection)
        return connection unless connection.is_a?(Hash)

        date_fields = %w[connectedAt lastUsedAt createdAt]
        date_fields.each do |field|
          connection[field] = Time.parse(connection[field]) if connection[field].is_a?(String)
        end
        connection
      end

      def convert_connection_details_dates(connection)
        return connection unless connection.is_a?(Hash)

        date_fields = %w[connectedAt lastUsedAt lastErrorAt createdAt updatedAt]
        date_fields.each do |field|
          connection[field] = Time.parse(connection[field]) if connection[field].is_a?(String)
        end
        connection
      end

      def convert_log_dates(log)
        return log unless log.is_a?(Hash)

        log["createdAt"] = Time.parse(log["createdAt"]) if log["createdAt"].is_a?(String)
        log
      end
    end
  end
end
