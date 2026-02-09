# frozen_string_literal: true

require "uri"

module Stack0
  module Integrations
    # CRM operations client
    class CRM
      def initialize(http)
        @http = http
      end

      # List contacts from a CRM connection
      #
      # @param connection_id [String] Connection ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order (asc/desc)
      # @return [Hash] Paginated list of contacts
      def list_contacts(connection_id:, cursor: nil, limit: nil, sort_by: nil, sort_order: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order

        query = URI.encode_www_form(params)
        @http.get("/integrations/crm/contacts?#{query}")
      end

      # Get a contact by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Contact ID
      # @return [Hash] Contact details
      def get_contact(connection_id:, id:)
        @http.get("/integrations/crm/contacts/#{id}?connectionId=#{connection_id}")
      end

      # Create a contact
      #
      # @param connection_id [String] Connection ID
      # @param data [Hash] Contact data
      # @return [Hash] Created contact
      def create_contact(connection_id:, data:)
        @http.post("/integrations/crm/contacts", { connectionId: connection_id, data: data })
      end

      # Update a contact
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Contact ID
      # @param data [Hash] Contact data to update
      # @return [Hash] Updated contact
      def update_contact(connection_id:, id:, data:)
        @http.patch("/integrations/crm/contacts/#{id}", { connectionId: connection_id, data: data })
      end

      # Delete a contact
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Contact ID
      # @return [Hash] Success response
      def delete_contact(connection_id:, id:)
        @http.delete("/integrations/crm/contacts/#{id}?connectionId=#{connection_id}")
      end

      # List companies from a CRM connection
      #
      # @param connection_id [String] Connection ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order (asc/desc)
      # @return [Hash] Paginated list of companies
      def list_companies(connection_id:, cursor: nil, limit: nil, sort_by: nil, sort_order: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order

        query = URI.encode_www_form(params)
        @http.get("/integrations/crm/companies?#{query}")
      end

      # Get a company by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Company ID
      # @return [Hash] Company details
      def get_company(connection_id:, id:)
        @http.get("/integrations/crm/companies/#{id}?connectionId=#{connection_id}")
      end

      # Create a company
      #
      # @param connection_id [String] Connection ID
      # @param data [Hash] Company data
      # @return [Hash] Created company
      def create_company(connection_id:, data:)
        @http.post("/integrations/crm/companies", { connectionId: connection_id, data: data })
      end

      # Update a company
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Company ID
      # @param data [Hash] Company data to update
      # @return [Hash] Updated company
      def update_company(connection_id:, id:, data:)
        @http.patch("/integrations/crm/companies/#{id}", { connectionId: connection_id, data: data })
      end

      # Delete a company
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Company ID
      # @return [Hash] Success response
      def delete_company(connection_id:, id:)
        @http.delete("/integrations/crm/companies/#{id}?connectionId=#{connection_id}")
      end

      # List deals from a CRM connection
      #
      # @param connection_id [String] Connection ID
      # @param cursor [String, nil] Pagination cursor
      # @param limit [Integer, nil] Maximum number of results
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order (asc/desc)
      # @return [Hash] Paginated list of deals
      def list_deals(connection_id:, cursor: nil, limit: nil, sort_by: nil, sort_order: nil)
        params = { connectionId: connection_id }
        params[:cursor] = cursor if cursor
        params[:limit] = limit if limit
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order

        query = URI.encode_www_form(params)
        @http.get("/integrations/crm/deals?#{query}")
      end

      # Get a deal by ID
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Deal ID
      # @return [Hash] Deal details
      def get_deal(connection_id:, id:)
        @http.get("/integrations/crm/deals/#{id}?connectionId=#{connection_id}")
      end

      # Create a deal
      #
      # @param connection_id [String] Connection ID
      # @param data [Hash] Deal data
      # @return [Hash] Created deal
      def create_deal(connection_id:, data:)
        @http.post("/integrations/crm/deals", { connectionId: connection_id, data: data })
      end

      # Update a deal
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Deal ID
      # @param data [Hash] Deal data to update
      # @return [Hash] Updated deal
      def update_deal(connection_id:, id:, data:)
        @http.patch("/integrations/crm/deals/#{id}", { connectionId: connection_id, data: data })
      end

      # Delete a deal
      #
      # @param connection_id [String] Connection ID
      # @param id [String] Deal ID
      # @return [Hash] Success response
      def delete_deal(connection_id:, id:)
        @http.delete("/integrations/crm/deals/#{id}?connectionId=#{connection_id}")
      end
    end
  end
end
