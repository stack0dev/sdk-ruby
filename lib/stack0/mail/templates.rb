# frozen_string_literal: true

module Stack0
  module Mail
    # Templates client for managing email templates
    class Templates
      def initialize(http)
        @http = http
      end

      # List all templates
      #
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param is_active [Boolean, nil] Filter by active status
      # @param search [String, nil] Search query
      # @return [Hash] Paginated list of templates
      def list(environment: nil, limit: nil, offset: nil, is_active: nil, search: nil)
        params = {}
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:isActive] = is_active.to_s unless is_active.nil?
        params[:search] = search if search

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/templates#{query}")
      end

      # Get a template by ID
      #
      # @param id [String] Template ID
      # @return [Hash] Template details
      def get(id)
        @http.get("/mail/templates/#{id}")
      end

      # Get a template by slug
      #
      # @param slug [String] Template slug
      # @return [Hash] Template details
      def get_by_slug(slug)
        @http.get("/mail/templates/slug/#{slug}")
      end

      # Create a new template
      #
      # @param name [String] Template name
      # @param slug [String] Template slug
      # @param subject [String] Email subject
      # @param html [String] HTML content
      # @param environment [String, nil] Environment
      # @param description [String, nil] Template description
      # @param preview_text [String, nil] Preview text
      # @param text [String, nil] Plain text content
      # @param maily_json [Hash, nil] Maily JSON data
      # @param variables_schema [Hash, nil] Variables schema
      # @param is_active [Boolean, nil] Active status
      # @return [Hash] Created template
      def create(name:, slug:, subject:, html:, environment: nil, description: nil,
                 preview_text: nil, text: nil, maily_json: nil, variables_schema: nil, is_active: nil)
        body = { name: name, slug: slug, subject: subject, html: html }
        body[:environment] = environment if environment
        body[:description] = description if description
        body[:previewText] = preview_text if preview_text
        body[:text] = text if text
        body[:mailyJson] = maily_json if maily_json
        body[:variablesSchema] = variables_schema if variables_schema
        body[:isActive] = is_active unless is_active.nil?

        @http.post("/mail/templates", body)
      end

      # Update a template
      #
      # @param id [String] Template ID
      # @param name [String, nil] Template name
      # @param slug [String, nil] Template slug
      # @param description [String, nil] Template description
      # @param subject [String, nil] Email subject
      # @param preview_text [String, nil] Preview text
      # @param html [String, nil] HTML content
      # @param text [String, nil] Plain text content
      # @param maily_json [Hash, nil] Maily JSON data
      # @param variables_schema [Hash, nil] Variables schema
      # @param is_active [Boolean, nil] Active status
      # @return [Hash] Updated template
      def update(id:, name: nil, slug: nil, description: nil, subject: nil,
                 preview_text: nil, html: nil, text: nil, maily_json: nil, variables_schema: nil, is_active: nil)
        body = {}
        body[:name] = name if name
        body[:slug] = slug if slug
        body[:description] = description if description
        body[:subject] = subject if subject
        body[:previewText] = preview_text if preview_text
        body[:html] = html if html
        body[:text] = text if text
        body[:mailyJson] = maily_json if maily_json
        body[:variablesSchema] = variables_schema if variables_schema
        body[:isActive] = is_active unless is_active.nil?

        @http.put("/mail/templates/#{id}", body)
      end

      # Delete a template
      #
      # @param id [String] Template ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete("/mail/templates/#{id}")
      end

      # Preview a template with variables
      #
      # @param id [String] Template ID
      # @param variables [Hash] Variables for rendering
      # @return [Hash] Rendered template preview
      def preview(id:, variables:)
        @http.post("/mail/templates/#{id}/preview", { variables: variables })
      end
    end
  end
end
