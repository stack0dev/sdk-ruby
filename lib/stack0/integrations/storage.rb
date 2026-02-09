# frozen_string_literal: true

require "uri"
require "base64"

module Stack0
  module Integrations
    # Storage operations client
    class Storage
      def initialize(http)
        @http = http
      end

      # List files from a storage connection
      #
      # @param connection_id [String] Connection ID
      # @param folder_id [String, nil] Folder ID to filter by
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of files
      def list_files(connection_id:, folder_id: nil, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:folderId] = folder_id if folder_id
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/storage/files?#{query}")
      end

      # Get a file by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] File ID
      # @return [Hash] File details
      def get_file(connection_id:, id:)
        @http.get("/integrations/storage/files/#{id}?connectionId=#{connection_id}")
      end

      # Upload a file
      #
      # @param connection_id [String] Connection ID
      # @param name [String] File name
      # @param mime_type [String] MIME type
      # @param data [String] File data (will be base64 encoded)
      # @param folder_id [String, nil] Folder ID to upload to
      # @return [Hash] Uploaded file details
      def upload_file(connection_id:, name:, mime_type:, data:, folder_id: nil)
        base64_data = Base64.strict_encode64(data)

        body = {
          connectionId: connection_id,
          name: name,
          mimeType: mime_type,
          data: base64_data
        }
        body[:folderId] = folder_id if folder_id

        @http.post("/integrations/storage/files", body)
      end

      # Delete a file
      #
      # @param connection_id [String] Connection ID
      # @param id [String] File ID
      # @return [Hash] Success response
      def delete_file(connection_id:, id:)
        @http.delete("/integrations/storage/files/#{id}?connectionId=#{connection_id}")
      end

      # Download a file
      #
      # @param connection_id [String] Connection ID
      # @param id [String] File ID
      # @return [Hash] File data with :data (binary), :mime_type, :filename
      def download_file(connection_id:, id:)
        response = @http.get("/integrations/storage/files/#{id}/download?connectionId=#{connection_id}")
        {
          data: Base64.decode64(response["data"]),
          mime_type: response["mimeType"],
          filename: response["filename"]
        }
      end

      # List folders from a storage connection
      #
      # @param connection_id [String] Connection ID
      # @param parent_id [String, nil] Parent folder ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Paginated list of folders
      def list_folders(connection_id:, parent_id: nil, cursor: nil, limit: nil)
        params = { connectionId: connection_id }
        params[:parentId] = parent_id if parent_id
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/integrations/storage/folders?#{query}")
      end

      # Get a folder by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Folder ID
      # @return [Hash] Folder details
      def get_folder(connection_id:, id:)
        @http.get("/integrations/storage/folders/#{id}?connectionId=#{connection_id}")
      end

      # Create a folder
      #
      # @param connection_id [String] Connection ID
      # @param name [String] Folder name
      # @param parent_id [String, nil] Parent folder ID
      # @return [Hash] Created folder
      def create_folder(connection_id:, name:, parent_id: nil)
        body = { connectionId: connection_id, name: name }
        body[:parentId] = parent_id if parent_id

        @http.post("/integrations/storage/folders", body)
      end

      # Delete a folder
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Folder ID
      # @return [Hash] Success response
      def delete_folder(connection_id:, id:)
        @http.delete("/integrations/storage/folders/#{id}?connectionId=#{connection_id}")
      end
    end
  end
end
