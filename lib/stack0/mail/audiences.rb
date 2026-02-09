# frozen_string_literal: true

module Stack0
  module Mail
    # Audiences client for managing contact lists
    class Audiences
      def initialize(http)
        @http = http
      end

      # List all audiences
      #
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @return [Hash] Paginated list of audiences
      def list(environment: nil, limit: nil, offset: nil, search: nil)
        params = {}
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/audiences#{query}")
      end

      # Get an audience by ID
      #
      # @param id [String] Audience ID
      # @return [Hash] Audience details
      def get(id)
        @http.get("/mail/audiences/#{id}")
      end

      # Create a new audience
      #
      # @param name [String] Audience name
      # @param environment [String, nil] Environment
      # @param description [String, nil] Audience description
      # @return [Hash] Created audience
      def create(name:, environment: nil, description: nil)
        body = { name: name }
        body[:environment] = environment if environment
        body[:description] = description if description

        @http.post("/mail/audiences", body)
      end

      # Update an audience
      #
      # @param id [String] Audience ID
      # @param name [String, nil] Audience name
      # @param description [String, nil] Audience description
      # @return [Hash] Updated audience
      def update(id:, name: nil, description: nil)
        body = {}
        body[:name] = name if name
        body[:description] = description if description

        @http.put("/mail/audiences/#{id}", body)
      end

      # Delete an audience
      #
      # @param id [String] Audience ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete("/mail/audiences/#{id}")
      end

      # List contacts in an audience
      #
      # @param id [String] Audience ID
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @param status [String, nil] Contact status filter
      # @return [Hash] Paginated list of contacts
      def list_contacts(id:, environment: nil, limit: nil, offset: nil, search: nil, status: nil)
        params = {}
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search
        params[:status] = status if status

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/audiences/#{id}/contacts#{query}")
      end

      # Add contacts to an audience
      #
      # @param id [String] Audience ID
      # @param contact_ids [Array<String>] Contact IDs to add
      # @return [Hash] Success response with added count
      def add_contacts(id:, contact_ids:)
        @http.post("/mail/audiences/#{id}/contacts", { contactIds: contact_ids })
      end

      # Remove contacts from an audience
      #
      # @param id [String] Audience ID
      # @param contact_ids [Array<String>] Contact IDs to remove
      # @return [Hash] Success response with removed count
      def remove_contacts(id:, contact_ids:)
        @http.delete_with_body("/mail/audiences/#{id}/contacts", { contactIds: contact_ids })
      end
    end
  end
end
