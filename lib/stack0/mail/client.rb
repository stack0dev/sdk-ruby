# frozen_string_literal: true

require "time"
require "uri"

require_relative "domains"
require_relative "templates"
require_relative "audiences"
require_relative "contacts"
require_relative "campaigns"
require_relative "sequences"
require_relative "events"

module Stack0
  module Mail
    # Main Mail client for sending emails and managing email features
    class Client
      attr_reader :domains, :templates, :audiences, :contacts, :campaigns, :sequences, :events

      def initialize(http)
        @http = http
        @domains = Domains.new(http)
        @templates = Templates.new(http)
        @audiences = Audiences.new(http)
        @contacts = Contacts.new(http)
        @campaigns = Campaigns.new(http)
        @sequences = Sequences.new(http)
        @events = Events.new(http)
      end

      # Send a single email
      #
      # @param from [String, Hash] Sender (email string or hash with email and name)
      # @param to [String, Array] Recipient(s)
      # @param subject [String] Email subject
      # @param html [String, nil] HTML content
      # @param text [String, nil] Plain text content
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param cc [String, Array, nil] CC recipient(s)
      # @param bcc [String, Array, nil] BCC recipient(s)
      # @param reply_to [String, nil] Reply-to address
      # @param template_id [String, nil] Template ID
      # @param template_variables [Hash, nil] Template variables
      # @param tags [Array<String>, nil] Email tags
      # @param metadata [Hash, nil] Custom metadata
      # @param attachments [Array<Hash>, nil] File attachments
      # @param headers [Hash, nil] Custom headers
      # @param scheduled_at [Time, String, nil] Scheduled send time
      # @return [Hash] Send result with email ID
      def send(from:, to:, subject:, html: nil, text: nil, project_slug: nil, environment: nil,
               cc: nil, bcc: nil, reply_to: nil, template_id: nil, template_variables: nil,
               tags: nil, metadata: nil, attachments: nil, headers: nil, scheduled_at: nil)
        body = { from: from, to: to, subject: subject }
        body[:html] = html if html
        body[:text] = text if text
        body[:projectSlug] = project_slug if project_slug
        body[:environment] = environment if environment
        body[:cc] = cc if cc
        body[:bcc] = bcc if bcc
        body[:replyTo] = reply_to if reply_to
        body[:templateId] = template_id if template_id
        body[:templateVariables] = template_variables if template_variables
        body[:tags] = tags if tags
        body[:metadata] = metadata if metadata
        body[:attachments] = attachments if attachments
        body[:headers] = headers if headers
        body[:scheduledAt] = format_time(scheduled_at) if scheduled_at

        @http.post("/mail/send", body)
      end

      # Send multiple emails in a batch (up to 100)
      #
      # @param emails [Array<Hash>] Array of email objects
      # @param project_slug [String, nil] Project slug
      # @return [Hash] Batch send result
      def send_batch(emails:, project_slug: nil)
        body = { emails: emails }
        body[:projectSlug] = project_slug if project_slug

        @http.post("/mail/send/batch", body)
      end

      # Send a broadcast email (same content to multiple recipients)
      #
      # @param from [String, Hash] Sender
      # @param to [Array] Recipients (up to 1000)
      # @param subject [String] Email subject
      # @param html [String, nil] HTML content
      # @param text [String, nil] Plain text content
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param template_id [String, nil] Template ID
      # @param template_variables [Hash, nil] Template variables
      # @param tags [Array<String>, nil] Email tags
      # @param metadata [Hash, nil] Custom metadata
      # @param scheduled_at [Time, String, nil] Scheduled send time
      # @return [Hash] Broadcast send result
      def send_broadcast(from:, to:, subject:, html: nil, text: nil, project_slug: nil, environment: nil,
                         template_id: nil, template_variables: nil, tags: nil, metadata: nil, scheduled_at: nil)
        body = { from: from, to: to, subject: subject }
        body[:html] = html if html
        body[:text] = text if text
        body[:projectSlug] = project_slug if project_slug
        body[:environment] = environment if environment
        body[:templateId] = template_id if template_id
        body[:templateVariables] = template_variables if template_variables
        body[:tags] = tags if tags
        body[:metadata] = metadata if metadata
        body[:scheduledAt] = format_time(scheduled_at) if scheduled_at

        @http.post("/mail/send/broadcast", body)
      end

      # Get email details by ID
      #
      # @param id [String] Email ID
      # @return [Hash] Email details
      def get(id)
        convert_dates(@http.get("/mail/#{id}"))
      end

      # List emails with optional filters
      #
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @param status [String, nil] Status filter
      # @param from [String, nil] From address filter
      # @param to [String, nil] To address filter
      # @param subject [String, nil] Subject filter
      # @param tag [String, nil] Tag filter
      # @param start_date [Time, String, nil] Start date filter
      # @param end_date [Time, String, nil] End date filter
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order (asc/desc)
      # @return [Hash] Paginated list of emails
      def list(project_slug: nil, environment: nil, limit: nil, offset: nil, status: nil,
               from: nil, to: nil, subject: nil, tag: nil, start_date: nil, end_date: nil,
               sort_by: nil, sort_order: nil)
        params = {}
        params[:projectSlug] = project_slug if project_slug
        params[:environment] = environment if environment
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:status] = status if status
        params[:from] = from if from
        params[:to] = to if to
        params[:subject] = subject if subject
        params[:tag] = tag if tag
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/mail#{query}")
        response["emails"] = response["emails"].map { |e| convert_dates(e) } if response["emails"]
        response
      end

      # Resend a previously sent email
      #
      # @param id [String] Email ID
      # @return [Hash] Resend result
      def resend(id)
        @http.post("/mail/#{id}/resend", {})
      end

      # Cancel a scheduled email
      #
      # @param id [String] Email ID
      # @return [Hash] Success response
      def cancel(id)
        @http.post("/mail/#{id}/cancel", {})
      end

      # Get overall email analytics
      #
      # @return [Hash] Email analytics
      def get_analytics
        @http.get("/mail/analytics")
      end

      # Get time series analytics (daily breakdown)
      #
      # @param days [Integer, nil] Number of days
      # @return [Hash] Time series data
      def get_time_series_analytics(days: nil)
        params = {}
        params[:days] = days if days
        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/analytics/timeseries#{query}")
      end

      # Get hourly analytics
      #
      # @return [Hash] Hourly analytics data
      def get_hourly_analytics
        @http.get("/mail/analytics/hourly")
      end

      # List unique senders with their statistics
      #
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param search [String, nil] Search query
      # @return [Hash] List of senders
      def list_senders(project_slug: nil, environment: nil, search: nil)
        params = {}
        params[:projectSlug] = project_slug if project_slug
        params[:environment] = environment if environment
        params[:search] = search if search
        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/mail/senders#{query}")
      end

      private

      def format_time(time)
        return time if time.is_a?(String)

        time.respond_to?(:iso8601) ? time.iso8601 : time.to_s
      end

      def convert_dates(hash)
        return hash unless hash.is_a?(Hash)

        date_fields = %w[createdAt sentAt deliveredAt openedAt clickedAt bouncedAt updatedAt]
        date_fields.each do |field|
          hash[field] = Time.parse(hash[field]) if hash[field].is_a?(String)
        end
        hash
      end
    end
  end
end
