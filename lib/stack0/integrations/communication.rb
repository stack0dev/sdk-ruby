# frozen_string_literal: true

require "uri"

module Stack0
  module Integrations
    # Communication operations client
    class Communication
      def initialize(http)
        @http = http
      end

      # List channels from a communication connection
      #
      # @param connection_id [String] Connection ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of channels
      def list_channels(connection_id:, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/communication/channels?#{query}")
      end

      # Get a channel by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Channel ID
      # @return [Hash] Channel details
      def get_channel(connection_id:, id:)
        @http.get("/integrations/communication/channels/#{id}?connectionId=#{connection_id}")
      end

      # List messages from a channel
      #
      # @param connection_id [String] Connection ID
      # @param channel_id [String] Channel ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of messages
      def list_messages(connection_id:, channel_id:, cursor: nil, limit: nil)
        params = { connectionId: connection_id, channelId: channel_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/communication/messages?#{query}")
      end

      # Send a message
      #
      # @param connection_id [String] Connection ID
      # @param channel_id [String] Channel ID
      # @param content [String] Message content
      # @return [Hash] Sent message
      def send_message(connection_id:, channel_id:, content:)
        @http.post("/integrations/communication/messages", {
          connectionId: connection_id,
          channelId: channel_id,
          content: content
        })
      end

      # List users from a communication connection
      #
      # @param connection_id [String] Connection ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of users
      def list_users(connection_id:, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/communication/users?#{query}")
      end
    end
  end
end
