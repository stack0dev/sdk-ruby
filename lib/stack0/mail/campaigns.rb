# frozen_string_literal: true

module Stack0
  module Mail
    # Campaigns client for managing email campaigns
    class Campaigns
      def initialize(http)
        @http = http
      end

      # List all campaigns
      #
      # @param environment [String, nil] Environment filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @param status [String, nil] Campaign status filter
      # @return [Hash] Paginated list of campaigns
      def list(environment: nil, limit: nil, offset: nil, search: nil, status: nil)
        params = {}
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search
        params[:status] = status if status

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/campaigns#{query}")
      end

      # Get a campaign by ID
      #
      # @param id [String] Campaign ID
      # @return [Hash] Campaign details
      def get(id)
        @http.get("/mail/campaigns/#{id}")
      end

      # Create a new campaign
      #
      # @param name [String] Campaign name
      # @param subject [String] Email subject
      # @param from_email [String] Sender email address
      # @param environment [String, nil] Environment
      # @param preview_text [String, nil] Preview text
      # @param from_name [String, nil] Sender name
      # @param reply_to [String, nil] Reply-to address
      # @param template_id [String, nil] Template ID
      # @param html [String, nil] HTML content
      # @param text [String, nil] Plain text content
      # @param audience_id [String, nil] Target audience ID
      # @param scheduled_at [Time, String, nil] Scheduled send time
      # @param tags [Array<String>, nil] Campaign tags
      # @return [Hash] Created campaign
      def create(name:, subject:, from_email:, environment: nil, preview_text: nil,
                 from_name: nil, reply_to: nil, template_id: nil, html: nil, text: nil,
                 audience_id: nil, scheduled_at: nil, tags: nil)
        body = { name: name, subject: subject, fromEmail: from_email }
        body[:environment] = environment if environment
        body[:previewText] = preview_text if preview_text
        body[:fromName] = from_name if from_name
        body[:replyTo] = reply_to if reply_to
        body[:templateId] = template_id if template_id
        body[:html] = html if html
        body[:text] = text if text
        body[:audienceId] = audience_id if audience_id
        body[:scheduledAt] = format_time(scheduled_at) if scheduled_at
        body[:tags] = tags if tags

        @http.post("/mail/campaigns", body)
      end

      # Update a campaign
      #
      # @param id [String] Campaign ID
      # @param name [String, nil] Campaign name
      # @param subject [String, nil] Email subject
      # @param preview_text [String, nil] Preview text
      # @param from_email [String, nil] Sender email address
      # @param from_name [String, nil] Sender name
      # @param reply_to [String, nil] Reply-to address
      # @param template_id [String, nil] Template ID
      # @param html [String, nil] HTML content
      # @param text [String, nil] Plain text content
      # @param audience_id [String, nil] Target audience ID
      # @param scheduled_at [Time, String, nil] Scheduled send time
      # @param tags [Array<String>, nil] Campaign tags
      # @return [Hash] Updated campaign
      def update(id:, name: nil, subject: nil, preview_text: nil, from_email: nil,
                 from_name: nil, reply_to: nil, template_id: nil, html: nil, text: nil,
                 audience_id: nil, scheduled_at: nil, tags: nil)
        body = {}
        body[:name] = name if name
        body[:subject] = subject if subject
        body[:previewText] = preview_text if preview_text
        body[:fromEmail] = from_email if from_email
        body[:fromName] = from_name if from_name
        body[:replyTo] = reply_to if reply_to
        body[:templateId] = template_id if template_id
        body[:html] = html if html
        body[:text] = text if text
        body[:audienceId] = audience_id if audience_id
        body[:scheduledAt] = format_time(scheduled_at) if scheduled_at
        body[:tags] = tags if tags

        @http.put("/mail/campaigns/#{id}", body)
      end

      # Delete a campaign
      #
      # @param id [String] Campaign ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete("/mail/campaigns/#{id}")
      end

      # Send a campaign
      #
      # @param id [String] Campaign ID
      # @param send_now [Boolean, nil] Send immediately
      # @param scheduled_at [Time, String, nil] Scheduled send time
      # @return [Hash] Send result with counts
      def send_campaign(id:, send_now: nil, scheduled_at: nil)
        body = {}
        body[:sendNow] = send_now unless send_now.nil?
        body[:scheduledAt] = format_time(scheduled_at) if scheduled_at

        @http.post("/mail/campaigns/#{id}/send", body)
      end

      # Pause a sending campaign
      #
      # @param id [String] Campaign ID
      # @return [Hash] Success response
      def pause(id)
        @http.post("/mail/campaigns/#{id}/pause", {})
      end

      # Cancel a campaign
      #
      # @param id [String] Campaign ID
      # @return [Hash] Success response
      def cancel(id)
        @http.post("/mail/campaigns/#{id}/cancel", {})
      end

      # Duplicate a campaign
      #
      # @param id [String] Campaign ID
      # @return [Hash] Duplicated campaign
      def duplicate(id)
        @http.post("/mail/campaigns/#{id}/duplicate", {})
      end

      # Get campaign statistics
      #
      # @param id [String] Campaign ID
      # @return [Hash] Campaign statistics
      def get_stats(id)
        @http.get("/mail/campaigns/#{id}/stats")
      end

      private

      def format_time(time)
        return time if time.is_a?(String)

        time.respond_to?(:iso8601) ? time.iso8601 : time.to_s
      end
    end
  end
end
