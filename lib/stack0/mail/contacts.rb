# frozen_string_literal: true

module Stack0
  module Mail
    # Contacts client for managing email contacts
    class Contacts
      def initialize(http)
        @http = http
      end

      # List all contacts
      #
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @param status [String, nil] Contact status filter
      # @return [Hash] Paginated list of contacts
      def list(environment: nil, limit: nil, offset: nil, search: nil, status: nil)
        params = {}
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search
        params[:status] = status if status

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/contacts#{query}")
      end

      # Get a contact by ID
      #
      # @param id [String] Contact ID
      # @return [Hash] Contact details
      def get(id)
        @http.get("/mail/contacts/#{id}")
      end

      # Create a new contact
      #
      # @param email [String] Contact email
      # @param environment [String, nil] Environment
      # @param first_name [String, nil] First name
      # @param last_name [String, nil] Last name
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Created contact
      def create(email:, environment: nil, first_name: nil, last_name: nil, metadata: nil)
        body = { email: email }
        body[:environment] = environment if environment
        body[:firstName] = first_name if first_name
        body[:lastName] = last_name if last_name
        body[:metadata] = metadata if metadata

        @http.post("/mail/contacts", body)
      end

      # Update a contact
      #
      # @param id [String] Contact ID
      # @param email [String, nil] Contact email
      # @param first_name [String, nil] First name
      # @param last_name [String, nil] Last name
      # @param metadata [Hash, nil] Custom metadata
      # @param status [String, nil] Contact status
      # @return [Hash] Updated contact
      def update(id:, email: nil, first_name: nil, last_name: nil, metadata: nil, status: nil)
        body = {}
        body[:email] = email if email
        body[:firstName] = first_name if first_name
        body[:lastName] = last_name if last_name
        body[:metadata] = metadata if metadata
        body[:status] = status if status

        @http.put("/mail/contacts/#{id}", body)
      end

      # Delete a contact
      #
      # @param id [String] Contact ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete("/mail/contacts/#{id}")
      end

      # Import contacts in bulk
      #
      # @param contacts [Array<Hash>] Contacts to import
      # @param environment [String, nil] Environment
      # @param audience_id [String, nil] Audience ID to add contacts to
      # @return [Hash] Import result with counts
      def import(contacts:, environment: nil, audience_id: nil)
        body = { contacts: contacts }
        body[:environment] = environment if environment
        body[:audienceId] = audience_id if audience_id

        @http.post("/mail/contacts/import", body)
      end
    end
  end
end
