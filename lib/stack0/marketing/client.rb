# frozen_string_literal: true

require "time"
require "uri"

module Stack0
  module Marketing
    # Main Marketing client for trend discovery and content management
    class Client
      def initialize(http)
        @http = http
      end

      # Discover new trends from all sources
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @return [Hash] Discovery result with trends_discovered and trends
      def discover_trends(project_slug:, environment:)
        @http.post("/marketing/trends/discover", {
          projectSlug: project_slug,
          environment: environment
        })
      end

      # List trends for a project
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param status [String, nil] Status filter
      # @param limit [Integer, nil] Maximum number of results
      # @return [Array<Hash>] List of trends
      def list_trends(project_slug:, environment:, status: nil, limit: nil)
        params = { projectSlug: project_slug, environment: environment }
        params[:status] = status if status
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/marketing/trends?#{query}")
      end

      # Get a single trend by ID
      #
      # @param trend_id [String] Trend ID
      # @return [Hash] Trend details
      def get_trend(trend_id)
        response = @http.get("/marketing/trends/#{trend_id}")
        convert_trend_dates(response)
      end

      # Update trend status
      #
      # @param trend_id [String] Trend ID
      # @param status [String] New status
      # @return [Hash] Update result
      def update_trend_status(trend_id:, status:)
        @http.patch("/marketing/trends/#{trend_id}/status", { status: status })
      end

      # Generate content opportunities from active trends
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @return [Hash] Generation result with opportunities_generated and opportunities
      def generate_opportunities(project_slug:, environment:)
        @http.post("/marketing/opportunities/generate", {
          projectSlug: project_slug,
          environment: environment
        })
      end

      # List opportunities for a project
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param status [String, nil] Status filter
      # @param limit [Integer, nil] Maximum number of results
      # @return [Array<Hash>] List of opportunities
      def list_opportunities(project_slug:, environment:, status: nil, limit: nil)
        params = { projectSlug: project_slug, environment: environment }
        params[:status] = status if status
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/marketing/opportunities?#{query}")
      end

      # Get a single opportunity by ID
      #
      # @param opportunity_id [String] Opportunity ID
      # @return [Hash] Opportunity details
      def get_opportunity(opportunity_id)
        response = @http.get("/marketing/opportunities/#{opportunity_id}")
        convert_opportunity_dates(response)
      end

      # Dismiss an opportunity
      #
      # @param opportunity_id [String] Opportunity ID
      # @return [Hash] Success response
      def dismiss_opportunity(opportunity_id)
        @http.post("/marketing/opportunities/#{opportunity_id}/dismiss", {})
      end

      # Create new marketing content
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param content_type [String] Content type (e.g., 'tiktok_slideshow')
      # @param title [String] Content title
      # @param opportunity_id [String, nil] Opportunity ID
      # @return [Hash] Created content
      def create_content(project_slug:, environment:, content_type:, title:, opportunity_id: nil)
        body = {
          projectSlug: project_slug,
          environment: environment,
          contentType: content_type,
          title: title
        }
        body[:opportunityId] = opportunity_id if opportunity_id

        response = @http.post("/marketing/content", body)
        convert_content_dates(response)
      end

      # List content with filters
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param status [String, nil] Status filter
      # @param content_type [String, nil] Content type filter
      # @param approval_status [String, nil] Approval status filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Array<Hash>] List of content
      def list_content(project_slug:, environment:, status: nil, content_type: nil,
                       approval_status: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug, environment: environment }
        params[:status] = status if status
        params[:contentType] = content_type if content_type
        params[:approvalStatus] = approval_status if approval_status
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        query = URI.encode_www_form(params)
        response = @http.get("/marketing/content?#{query}")
        response.map { |c| convert_content_dates(c) }
      end

      # Get a single content by ID
      #
      # @param content_id [String] Content ID
      # @return [Hash] Content details
      def get_content(content_id)
        response = @http.get("/marketing/content/#{content_id}")
        convert_content_dates(response)
      end

      # Update content
      #
      # @param content_id [String] Content ID
      # @param title [String, nil] New title
      # @param status [String, nil] New status
      # @return [Hash] Updated content
      def update_content(content_id:, title: nil, status: nil)
        body = {}
        body[:title] = title if title
        body[:status] = status if status

        response = @http.patch("/marketing/content/#{content_id}", body)
        convert_content_dates(response)
      end

      # Approve content for publishing
      #
      # @param content_id [String] Content ID
      # @param review_notes [String, nil] Review notes
      # @return [Hash] Approved content
      def approve_content(content_id:, review_notes: nil)
        body = { contentId: content_id }
        body[:reviewNotes] = review_notes if review_notes

        response = @http.post("/marketing/content/#{content_id}/approve", body)
        convert_content_dates(response)
      end

      # Reject content
      #
      # @param content_id [String] Content ID
      # @param review_notes [String, nil] Review notes
      # @return [Hash] Rejected content
      def reject_content(content_id:, review_notes: nil)
        body = { contentId: content_id }
        body[:reviewNotes] = review_notes if review_notes

        response = @http.post("/marketing/content/#{content_id}/reject", body)
        convert_content_dates(response)
      end

      # Delete content
      #
      # @param content_id [String] Content ID
      # @return [Hash] Success response
      def delete_content(content_id)
        @http.delete("/marketing/content/#{content_id}")
      end

      # Create a new script
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param hook [String] Hook line
      # @param slides [Array<Hash>] Slide data
      # @param cta [String] Call to action
      # @param content_id [String, nil] Content ID
      # @return [Hash] Created script
      def create_script(project_slug:, environment:, hook:, slides:, cta:, content_id: nil)
        body = {
          projectSlug: project_slug,
          environment: environment,
          hook: hook,
          slides: slides,
          cta: cta
        }
        body[:contentId] = content_id if content_id

        response = @http.post("/marketing/scripts", body)
        convert_script_dates(response)
      end

      # List scripts
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param content_id [String, nil] Content ID filter
      # @param limit [Integer, nil] Maximum number of results
      # @return [Array<Hash>] List of scripts
      def list_scripts(project_slug:, environment:, content_id: nil, limit: nil)
        params = { projectSlug: project_slug, environment: environment }
        params[:contentId] = content_id if content_id
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        response = @http.get("/marketing/scripts?#{query}")
        response.map { |s| convert_script_dates(s) }
      end

      # Get a single script by ID
      #
      # @param script_id [String] Script ID
      # @return [Hash] Script details
      def get_script(script_id)
        response = @http.get("/marketing/scripts/#{script_id}")
        convert_script_dates(response)
      end

      # Update a script
      #
      # @param script_id [String] Script ID
      # @param hook [String, nil] Hook line
      # @param slides [Array<Hash>, nil] Slide data
      # @param cta [String, nil] Call to action
      # @return [Hash] Updated script
      def update_script(script_id:, hook: nil, slides: nil, cta: nil)
        body = {}
        body[:hook] = hook if hook
        body[:slides] = slides if slides
        body[:cta] = cta if cta

        response = @http.patch("/marketing/scripts/#{script_id}", body)
        convert_script_dates(response)
      end

      # Create a new version of a script
      #
      # @param script_id [String] Script ID
      # @param hook [String] Hook line
      # @param slides [Array<Hash>] Slide data
      # @param cta [String] Call to action
      # @return [Hash] New script version
      def create_script_version(script_id:, hook:, slides:, cta:)
        response = @http.post("/marketing/scripts/#{script_id}/versions", {
          hook: hook,
          slides: slides,
          cta: cta
        })
        convert_script_dates(response)
      end

      # Get all versions of a script
      #
      # @param script_id [String] Script ID
      # @return [Array<Hash>] List of script versions
      def get_script_versions(script_id)
        response = @http.get("/marketing/scripts/#{script_id}/versions")
        response.map { |s| convert_script_dates(s) }
      end

      # Delete a script
      #
      # @param script_id [String] Script ID
      # @return [Hash] Success response
      def delete_script(script_id)
        @http.delete("/marketing/scripts/#{script_id}")
      end

      # Get analytics overview
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param start_date [Time, nil] Start date
      # @param end_date [Time, nil] End date
      # @return [Hash] Analytics overview
      def get_analytics_overview(project_slug:, environment:, start_date: nil, end_date: nil)
        params = { projectSlug: project_slug, environment: environment }
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date

        query = URI.encode_www_form(params)
        @http.get("/marketing/analytics/overview?#{query}")
      end

      # Get content performance metrics
      #
      # @param project_slug [String] Project slug
      # @param environment [String] Environment
      # @param content_type [String, nil] Content type filter
      # @param limit [Integer, nil] Maximum number of results
      # @return [Hash] Content performance data
      def get_content_performance(project_slug:, environment:, content_type: nil, limit: nil)
        params = { projectSlug: project_slug, environment: environment }
        params[:contentType] = content_type if content_type
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        @http.get("/marketing/analytics/performance?#{query}")
      end

      # Get trend discovery analytics
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @param start_date [Time, nil] Start date
      # @param end_date [Time, nil] End date
      # @return [Hash] Trend analytics data
      def get_trend_analytics(project_slug:, environment: nil, start_date: nil, end_date: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date

        query = URI.encode_www_form(params)
        @http.get("/marketing/analytics/trends?#{query}")
      end

      # Get opportunity conversion analytics
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @param start_date [Time, nil] Start date
      # @param end_date [Time, nil] End date
      # @return [Hash] Opportunity conversion data
      def get_opportunity_conversion(project_slug:, environment: nil, start_date: nil, end_date: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date

        query = URI.encode_www_form(params)
        @http.get("/marketing/analytics/conversion?#{query}")
      end

      # Schedule content for publishing
      #
      # @param project_slug [String] Project slug
      # @param content_id [String] Content ID
      # @param scheduled_for [Time] Scheduled time
      # @param auto_publish [Boolean, nil] Whether to auto-publish
      # @param environment [String, nil] Environment
      # @return [Hash] Calendar entry
      def schedule_content(project_slug:, content_id:, scheduled_for:, auto_publish: nil, environment: nil)
        body = {
          projectSlug: project_slug,
          contentId: content_id,
          scheduledFor: format_time(scheduled_for)
        }
        body[:autoPublish] = auto_publish unless auto_publish.nil?
        body[:environment] = environment if environment

        response = @http.post("/marketing/calendar/schedule", body)
        convert_calendar_entry_dates(response)
      end

      # List scheduled content
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @param start_date [Time, nil] Start date
      # @param end_date [Time, nil] End date
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Array<Hash>] List of calendar entries
      def list_calendar_entries(project_slug:, environment: nil, start_date: nil, end_date: nil,
                                limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        query = URI.encode_www_form(params)
        response = @http.get("/marketing/calendar?#{query}")
        response.map { |e| convert_calendar_entry_dates(e) }
      end

      # Get a single calendar entry by ID
      #
      # @param entry_id [String] Entry ID
      # @return [Hash] Calendar entry details
      def get_calendar_entry(entry_id)
        response = @http.get("/marketing/calendar/#{entry_id}")
        convert_calendar_entry_dates(response)
      end

      # Update a calendar entry
      #
      # @param entry_id [String] Entry ID
      # @param scheduled_for [Time, nil] New scheduled time
      # @param auto_publish [Boolean, nil] Whether to auto-publish
      # @return [Hash] Updated calendar entry
      def update_calendar_entry(entry_id:, scheduled_for: nil, auto_publish: nil)
        body = {}
        body[:scheduledFor] = format_time(scheduled_for) if scheduled_for
        body[:autoPublish] = auto_publish unless auto_publish.nil?

        response = @http.patch("/marketing/calendar/#{entry_id}", body)
        convert_calendar_entry_dates(response)
      end

      # Cancel a scheduled calendar entry
      #
      # @param entry_id [String] Entry ID
      # @return [Hash] Cancellation result
      def cancel_calendar_entry(entry_id)
        @http.post("/marketing/calendar/#{entry_id}/cancel", {})
      end

      # Mark content as published
      #
      # @param entry_id [String] Entry ID
      # @param published_at [Time, nil] Published time
      # @return [Hash] Updated calendar entry
      def mark_content_published(entry_id:, published_at: nil)
        body = {}
        body[:publishedAt] = format_time(published_at) if published_at

        response = @http.post("/marketing/calendar/#{entry_id}/published", body)
        convert_calendar_entry_dates(response)
      end

      # Create an asset generation job
      #
      # @param project_slug [String] Project slug
      # @param content_id [String] Content ID
      # @param job_type [String] Job type (e.g., 'slide_generation')
      # @param input [Hash, nil] Job input data
      # @param environment [String, nil] Environment
      # @return [Hash] Created asset job
      def create_asset_job(project_slug:, content_id:, job_type:, input: nil, environment: nil)
        body = {
          projectSlug: project_slug,
          contentId: content_id,
          jobType: job_type
        }
        body[:input] = input if input
        body[:environment] = environment if environment

        response = @http.post("/marketing/assets/jobs", body)
        convert_asset_job_dates(response)
      end

      # List asset jobs
      #
      # @param project_slug [String] Project slug
      # @param content_id [String, nil] Content ID filter
      # @param status [String, nil] Status filter
      # @param job_type [String, nil] Job type filter
      # @param limit [Integer, nil] Maximum number of results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Array<Hash>] List of asset jobs
      def list_asset_jobs(project_slug:, content_id: nil, status: nil, job_type: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:contentId] = content_id if content_id
        params[:status] = status if status
        params[:jobType] = job_type if job_type
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        query = URI.encode_www_form(params)
        response = @http.get("/marketing/assets/jobs?#{query}")
        response.map { |j| convert_asset_job_dates(j) }
      end

      # Get an asset job by ID
      #
      # @param job_id [String] Job ID
      # @return [Hash] Asset job details
      def get_asset_job(job_id)
        response = @http.get("/marketing/assets/jobs/#{job_id}")
        convert_asset_job_dates(response)
      end

      # Update asset job status
      #
      # @param job_id [String] Job ID
      # @param status [String] New status
      # @param output [Hash, nil] Job output
      # @param error [String, nil] Error message
      # @return [Hash] Updated asset job
      def update_asset_job_status(job_id:, status:, output: nil, error: nil)
        body = { status: status }
        body[:output] = output if output
        body[:error] = error if error

        response = @http.patch("/marketing/assets/jobs/#{job_id}/status", body)
        convert_asset_job_dates(response)
      end

      # Retry a failed asset job
      #
      # @param job_id [String] Job ID
      # @return [Hash] Retried asset job
      def retry_asset_job(job_id)
        response = @http.post("/marketing/assets/jobs/#{job_id}/retry", {})
        convert_asset_job_dates(response)
      end

      # Cancel an asset job
      #
      # @param job_id [String] Job ID
      # @return [Hash] Cancelled asset job
      def cancel_asset_job(job_id)
        response = @http.post("/marketing/assets/jobs/#{job_id}/cancel", {})
        convert_asset_job_dates(response)
      end

      # Get marketing settings for a project
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @return [Hash] Marketing settings
      def get_settings(project_slug:, environment: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment

        query = URI.encode_www_form(params)
        @http.get("/marketing/settings?#{query}")
      end

      # Update marketing settings
      #
      # @param project_slug [String] Project slug
      # @param brand_voice [String, nil] Brand voice description
      # @param monitored_keywords [Array<String>, nil] Keywords to monitor
      # @param environment [String, nil] Environment
      # @return [Hash] Update result
      def update_settings(project_slug:, brand_voice: nil, monitored_keywords: nil, environment: nil)
        body = { projectSlug: project_slug }
        body[:brandVoice] = brand_voice if brand_voice
        body[:monitoredKeywords] = monitored_keywords if monitored_keywords
        body[:environment] = environment if environment

        @http.post("/marketing/settings", body)
      end

      # Get current period usage
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @return [Hash] Current usage data
      def get_current_usage(project_slug:, environment: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment

        query = URI.encode_www_form(params)
        response = @http.get("/marketing/usage/current?#{query}")
        convert_usage_dates(response)
      end

      # Get usage history
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @param start_date [Time, nil] Start date
      # @param end_date [Time, nil] End date
      # @param limit [Integer, nil] Maximum number of results
      # @return [Array<Hash>] Usage history
      def get_usage_history(project_slug:, environment: nil, start_date: nil, end_date: nil, limit: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date
        params[:limit] = limit if limit

        query = URI.encode_www_form(params)
        response = @http.get("/marketing/usage/history?#{query}")
        response.map { |u| convert_marketing_usage_dates(u) }
      end

      # Get total usage across all periods
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @param start_date [Time, nil] Start date
      # @param end_date [Time, nil] End date
      # @return [Hash] Total usage data
      def get_total_usage(project_slug:, environment: nil, start_date: nil, end_date: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        params[:startDate] = format_time(start_date) if start_date
        params[:endDate] = format_time(end_date) if end_date

        query = URI.encode_www_form(params)
        @http.get("/marketing/usage/total?#{query}")
      end

      # Record usage
      #
      # @param project_slug [String] Project slug
      # @param usage_type [String] Type of usage
      # @param amount [Integer] Usage amount
      # @param environment [String, nil] Environment
      # @return [Hash] Recorded usage
      def record_usage(project_slug:, usage_type:, amount:, environment: nil)
        body = {
          projectSlug: project_slug,
          usageType: usage_type,
          amount: amount
        }
        body[:environment] = environment if environment

        response = @http.post("/marketing/usage/record", body)
        convert_marketing_usage_dates(response)
      end

      private

      def format_time(time)
        return time if time.is_a?(String)

        time.respond_to?(:iso8601) ? time.iso8601 : time.to_s
      end

      def convert_trend_dates(trend)
        return trend unless trend.is_a?(Hash)

        date_fields = %w[firstSeenAt lastUpdatedAt expiresAt createdAt]
        date_fields.each do |field|
          trend[field] = Time.parse(trend[field]) if trend[field].is_a?(String)
        end
        trend
      end

      def convert_opportunity_dates(opp)
        return opp unless opp.is_a?(Hash)

        date_fields = %w[createdAt expiresAt usedAt]
        date_fields.each do |field|
          opp[field] = Time.parse(opp[field]) if opp[field].is_a?(String)
        end
        opp
      end

      def convert_content_dates(content)
        return content unless content.is_a?(Hash)

        date_fields = %w[createdAt updatedAt reviewedAt publishedAt]
        date_fields.each do |field|
          content[field] = Time.parse(content[field]) if content[field].is_a?(String)
        end
        content
      end

      def convert_script_dates(script)
        return script unless script.is_a?(Hash)

        script["createdAt"] = Time.parse(script["createdAt"]) if script["createdAt"].is_a?(String)
        script
      end

      def convert_calendar_entry_dates(entry)
        return entry unless entry.is_a?(Hash)

        date_fields = %w[scheduledFor createdAt updatedAt publishedAt]
        date_fields.each do |field|
          entry[field] = Time.parse(entry[field]) if entry[field].is_a?(String)
        end
        entry
      end

      def convert_asset_job_dates(job)
        return job unless job.is_a?(Hash)

        date_fields = %w[createdAt startedAt completedAt]
        date_fields.each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end

      def convert_usage_dates(usage)
        return usage unless usage.is_a?(Hash)

        date_fields = %w[periodStart periodEnd]
        date_fields.each do |field|
          usage[field] = Time.parse(usage[field]) if usage[field].is_a?(String)
        end
        usage
      end

      def convert_marketing_usage_dates(usage)
        return usage unless usage.is_a?(Hash)

        date_fields = %w[periodStart periodEnd createdAt updatedAt]
        date_fields.each do |field|
          usage[field] = Time.parse(usage[field]) if usage[field].is_a?(String)
        end
        usage
      end
    end
  end
end
