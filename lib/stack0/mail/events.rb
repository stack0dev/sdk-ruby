# frozen_string_literal: true

module Stack0
  module Mail
    # Events client for tracking custom events
    class Events
      def initialize(http)
        @http = http
      end

      # List all event definitions
      #
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @return [Hash] Paginated list of events
      def list(project_slug: nil, environment: nil, limit: nil, offset: nil, search: nil)
        params = {}
        params[:projectSlug] = project_slug if project_slug
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/events#{query}")
      end

      # Get an event definition by ID
      #
      # @param id [String] Event ID
      # @return [Hash] Event details
      def get(id)
        @http.get("/mail/events/#{id}")
      end

      # Create a new event definition
      #
      # @param name [String] Event name
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param description [String, nil] Event description
      # @param properties_schema [Hash, nil] Properties schema
      # @return [Hash] Created event
      def create(name:, project_slug: nil, environment: nil, description: nil, properties_schema: nil)
        body = { name: name }
        body[:projectSlug] = project_slug if project_slug
        body[:environment] = environment if environment
        body[:description] = description if description
        body[:propertiesSchema] = properties_schema if properties_schema

        @http.post("/mail/events", body)
      end

      # Update an event definition
      #
      # @param id [String] Event ID
      # @param name [String, nil] Event name
      # @param description [String, nil] Event description
      # @param properties_schema [Hash, nil] Properties schema
      # @return [Hash] Updated event
      def update(id:, name: nil, description: nil, properties_schema: nil)
        body = {}
        body[:name] = name if name
        body[:description] = description if description
        body[:propertiesSchema] = properties_schema if properties_schema

        @http.put("/mail/events/#{id}", body)
      end

      # Delete an event definition
      #
      # @param id [String] Event ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete("/mail/events/#{id}")
      end

      # Track a single event
      #
      # @param event_name [String] Event name
      # @param environment [String, nil] Environment
      # @param contact_id [String, nil] Contact ID
      # @param contact_email [String, nil] Contact email
      # @param properties [Hash, nil] Event properties
      # @return [Hash] Track result
      def track(event_name:, environment: nil, contact_id: nil, contact_email: nil, properties: nil)
        body = { eventName: event_name }
        body[:environment] = environment if environment
        body[:contactId] = contact_id if contact_id
        body[:contactEmail] = contact_email if contact_email
        body[:properties] = properties if properties

        @http.post("/mail/events/track", body)
      end

      # Track multiple events in a batch
      #
      # @param events [Array<Hash>] Events to track
      # @param environment [String, nil] Environment
      # @return [Hash] Batch track result
      def track_batch(events:, environment: nil)
        body = { events: events }
        body[:environment] = environment if environment

        @http.post("/mail/events/track/batch", body)
      end

      # List event occurrences
      #
      # @param event_id [String, nil] Event ID filter
      # @param contact_id [String, nil] Contact ID filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param start_date [Time, String, nil] Start date filter
      # @param end_date [Time, String, nil] End date filter
      # @return [Hash] Paginated list of occurrences
      def list_occurrences(event_id: nil, contact_id: nil, limit: nil, offset: nil, start_date: nil, end_date: nil)
        params = {}
        params[:eventId] = event_id if event_id
        params[:contactId] = contact_id if contact_id
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/events/occurrences#{query}")
      end

      # Get analytics for an event
      #
      # @param id [String] Event ID
      # @return [Hash] Event analytics
      def get_analytics(id)
        @http.get("/mail/events/analytics/#{id}")
      end

      private

      def format_time(time)
        return time if time.is_a?(String)

        time.respond_to?(:iso8601) ? time.iso8601 : time.to_s
      end
    end
  end
end
