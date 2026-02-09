# frozen_string_literal: true

require "uri"

module Stack0
  module Integrations
    # Productivity operations client
    class Productivity
      def initialize(http)
        @http = http
      end

      # List documents from a productivity connection
      #
      # @param connection_id [String] Connection ID
      # @param parent_id [String, nil] Parent document/folder ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of documents
      def list_documents(connection_id:, parent_id: nil, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:parentId] = parent_id if parent_id
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/productivity/documents?#{query}")
      end

      # Get a document by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Document ID
      # @return [Hash] Document details
      def get_document(connection_id:, id:)
        @http.get("/integrations/productivity/documents/#{id}?connectionId=#{connection_id}")
      end

      # Create a document
      #
      # @param connection_id [String] Connection ID
      # @param title [String] Document title
      # @param content [String, nil] Document content
      # @param parent_id [String, nil] Parent document/folder ID
      # @return [Hash] Created document
      def create_document(connection_id:, title:, content: nil, parent_id: nil)
        body = { connectionId: connection_id, title: title }
        body[:content] = content if content
        body[:parentId] = parent_id if parent_id

        @http.post("/integrations/productivity/documents", body)
      end

      # Update a document
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Document ID
      # @param title [String, nil] Document title
      # @param content [String, nil] Document content
      # @return [Hash] Updated document
      def update_document(connection_id:, id:, title: nil, content: nil)
        body = { connectionId: connection_id }
        body[:title] = title if title
        body[:content] = content if content

        @http.patch("/integrations/productivity/documents/#{id}", body)
      end

      # List tables from a productivity connection
      #
      # @param connection_id [String] Connection ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of tables
      def list_tables(connection_id:, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/productivity/tables?#{query}")
      end

      # Get a table by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Table ID
      # @return [Hash] Table details
      def get_table(connection_id:, id:)
        @http.get("/integrations/productivity/tables/#{id}?connectionId=#{connection_id}")
      end

      # List rows from a table
      #
      # @param connection_id [String] Connection ID
      # @param table_id [String] Table ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of rows
      def list_table_rows(connection_id:, table_id:, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/productivity/tables/#{table_id}/rows?#{query}")
      end

      # Get a table row by ID
      #
      # @param connection_id [String] Connection ID
      # @param table_id [String] Table ID
      # @param row_id [String] Row ID
      # @return [Hash] Row details
      def get_table_row(connection_id:, table_id:, row_id:)
        @http.get("/integrations/productivity/tables/#{table_id}/rows/#{row_id}?connectionId=#{connection_id}")
      end

      # Create a table row
      #
      # @param connection_id [String] Connection ID
      # @param table_id [String] Table ID
      # @param fields [Hash] Row field values
      # @return [Hash] Created row
      def create_table_row(connection_id:, table_id:, fields:)
        @http.post("/integrations/productivity/tables/#{table_id}/rows", {
          connectionId: connection_id,
          fields: fields
        })
      end

      # Update a table row
      #
      # @param connection_id [String] Connection ID
      # @param table_id [String] Table ID
      # @param row_id [String] Row ID
      # @param fields [Hash] Row field values to update
      # @return [Hash] Updated row
      def update_table_row(connection_id:, table_id:, row_id:, fields:)
        @http.patch("/integrations/productivity/tables/#{table_id}/rows/#{row_id}", {
          connectionId: connection_id,
          fields: fields
        })
      end

      # Delete a table row
      #
      # @param connection_id [String] Connection ID
      # @param table_id [String] Table ID
      # @param row_id [String] Row ID
      # @return [Hash] Success response
      def delete_table_row(connection_id:, table_id:, row_id:)
        @http.delete("/integrations/productivity/tables/#{table_id}/rows/#{row_id}?connectionId=#{connection_id}")
      end
    end
  end
end
