# frozen_string_literal: true

module Stack0
  module Mail
    # Domains client for managing sending domains
    class Domains
      def initialize(http)
        @http = http
      end

      # List all domains for the organization
      #
      # @param project_slug [String] Project slug (required)
      # @param environment [String, nil] Environment (sandbox or production)
      # @return [Array<Hash>] List of domains
      def list(project_slug:, environment: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        query = URI.encode_www_form(params)
        @http.get("/mail/domains?#{query}")
      end

      # Add a new domain
      #
      # @param domain [String] Domain name to add
      # @return [Hash] Domain creation response with DNS records
      def add(domain:)
        @http.post("/mail/domains", { domain: domain })
      end

      # Get DNS records for a domain
      #
      # @param domain_id [String] Domain ID
      # @return [Hash] DNS records for the domain
      def get_dns_records(domain_id)
        @http.get("/mail/domains/#{domain_id}/dns")
      end

      # Verify a domain
      #
      # @param domain_id [String] Domain ID
      # @return [Hash] Verification result
      def verify(domain_id)
        @http.post("/mail/domains/#{domain_id}/verify", {})
      end

      # Delete a domain
      #
      # @param domain_id [String] Domain ID
      # @return [Hash] Success response
      def delete(domain_id)
        @http.delete("/mail/domains/#{domain_id}")
      end

      # Set a domain as the default
      #
      # @param domain_id [String] Domain ID
      # @return [Hash] Updated domain
      def set_default(domain_id)
        @http.post("/mail/domains/#{domain_id}/default", {})
      end
    end
  end
end
