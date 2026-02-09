# frozen_string_literal: true

require "time"
require "uri"

module Stack0
  module Extraction
    # Extraction client for extracting content from webpages using AI
    class Client
      include Polling

      def initialize(http)
        @http = http
      end

      # Extract content from a URL
      #
      # @param url [String] URL to extract from
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param mode [String, nil] Extraction mode (auto, schema, markdown, raw)
      # @param schema [Hash, nil] Schema for structured extraction
      # @param prompt [String, nil] Custom prompt
      # @param include_links [Boolean, nil] Include links
      # @param include_images [Boolean, nil] Include images
      # @param include_metadata [Boolean, nil] Include metadata
      # @param wait_for_selector [String, nil] CSS selector to wait for
      # @param wait_for_timeout [Integer, nil] Timeout in milliseconds
      # @param headers [Hash, nil] Custom headers
      # @param cookies [Array<Hash>, nil] Cookies to set
      # @param webhook_url [String, nil] Webhook URL
      # @param webhook_secret [String, nil] Webhook secret
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Extraction job with ID and status
      def extract(url:, environment: nil, project_id: nil, mode: nil, schema: nil, prompt: nil,
                  include_links: nil, include_images: nil, include_metadata: nil,
                  wait_for_selector: nil, wait_for_timeout: nil, headers: nil, cookies: nil,
                  webhook_url: nil, webhook_secret: nil, metadata: nil)
        body = { url: url }
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id
        body[:mode] = mode if mode
        body[:schema] = schema if schema
        body[:prompt] = prompt if prompt
        body[:includeLinks] = include_links unless include_links.nil?
        body[:includeImages] = include_images unless include_images.nil?
        body[:includeMetadata] = include_metadata unless include_metadata.nil?
        body[:waitForSelector] = wait_for_selector if wait_for_selector
        body[:waitForTimeout] = wait_for_timeout if wait_for_timeout
        body[:headers] = headers if headers
        body[:cookies] = cookies if cookies
        body[:webhookUrl] = webhook_url if webhook_url
        body[:webhookSecret] = webhook_secret if webhook_secret
        body[:metadata] = metadata if metadata

        @http.post("/webdata/extractions", body)
      end

      # Get an extraction by ID
      #
      # @param id [String] Extraction ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Extraction details
      def get(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        convert_dates(@http.get("/webdata/extractions/#{id}#{query}"))
      end

      # List extractions with pagination and filters
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param status [String, nil] Status filter
      # @param url [String, nil] URL filter
      # @param limit [Integer, nil] Maximum results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of extractions
      def list(environment: nil, project_id: nil, status: nil, url: nil, limit: nil, cursor: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:status] = status if status
        params[:url] = url if url
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/extractions#{query}")
        response["items"] = response["items"].map { |i| convert_dates(i) } if response["items"]
        response
      end

      # Delete an extraction
      #
      # @param id [String] Extraction ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def delete(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.delete_with_body("/webdata/extractions/#{id}#{query}", {
          id: id,
          environment: environment,
          projectId: project_id
        }.compact)
      end

      # Extract content and wait for completion
      #
      # @param poll_interval [Integer] Poll interval in seconds
      # @param timeout [Integer] Timeout in seconds
      # @param extract_options [Hash] Options passed to extract
      # @return [Hash] Completed extraction
      def extract_and_wait(poll_interval: 1, timeout: 60, **extract_options)
        response = extract(**extract_options)
        id = response["id"]
        start_time = Time.now

        loop do
          extraction = get(
            id: id,
            environment: extract_options[:environment],
            project_id: extract_options[:project_id]
          )

          return extraction if extraction["status"] == "completed"

          if extraction["status"] == "failed"
            raise Error, extraction["error"] || "Extraction failed"
          end

          if Time.now - start_time > timeout
            raise TimeoutError, "Extraction timed out"
          end

          sleep(poll_interval)
        end
      end

      # Create a batch extraction job
      #
      # @param urls [Array<String>] URLs to extract from
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param name [String, nil] Job name
      # @param config [Hash, nil] Extraction configuration
      # @param webhook_url [String, nil] Webhook URL
      # @param webhook_secret [String, nil] Webhook secret
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Batch job
      def batch(urls:, environment: nil, project_id: nil, name: nil, config: nil,
                webhook_url: nil, webhook_secret: nil, metadata: nil)
        body = { urls: urls }
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id
        body[:name] = name if name
        body[:config] = config if config
        body[:webhookUrl] = webhook_url if webhook_url
        body[:webhookSecret] = webhook_secret if webhook_secret
        body[:metadata] = metadata if metadata

        @http.post("/webdata/batch/extractions", body)
      end

      # Get a batch job by ID
      #
      # @param id [String] Batch job ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Batch job details
      def get_batch_job(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        convert_batch_job_dates(@http.get("/webdata/batch/#{id}#{query}"))
      end

      # List batch jobs
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param status [String, nil] Status filter
      # @param limit [Integer, nil] Maximum results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of batch jobs
      def list_batch_jobs(environment: nil, project_id: nil, status: nil, limit: nil, cursor: nil)
        params = { type: "extraction" }
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:status] = status if status
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/batch#{query}")
        response["items"] = response["items"].map { |i| convert_batch_job_dates(i) } if response["items"]
        response
      end

      # Cancel a batch job
      #
      # @param id [String] Batch job ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def cancel_batch_job(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.post("/webdata/batch/#{id}/cancel#{query}", {})
      end

      # Create a batch job and wait for completion
      #
      # @param poll_interval [Integer] Poll interval in seconds
      # @param timeout [Integer] Timeout in seconds
      # @param batch_options [Hash] Options passed to batch
      # @return [Hash] Completed batch job
      def batch_and_wait(poll_interval: 2, timeout: 300, **batch_options)
        response = batch(**batch_options)
        id = response["id"]
        start_time = Time.now

        loop do
          job = get_batch_job(
            id: id,
            environment: batch_options[:environment],
            project_id: batch_options[:project_id]
          )

          return job if %w[completed failed cancelled].include?(job["status"])

          if Time.now - start_time > timeout
            raise TimeoutError, "Batch job timed out"
          end

          sleep(poll_interval)
        end
      end

      # Create a scheduled extraction job
      #
      # @param name [String] Schedule name
      # @param url [String] URL to extract from
      # @param config [Hash] Extraction configuration
      # @param frequency [String, nil] Frequency (hourly, daily, weekly, monthly)
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param detect_changes [Boolean, nil] Detect changes
      # @param change_threshold [Numeric, nil] Change threshold
      # @param webhook_url [String, nil] Webhook URL
      # @param webhook_secret [String, nil] Webhook secret
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Created schedule
      def create_schedule(name:, url:, config:, frequency: nil, environment: nil, project_id: nil,
                          detect_changes: nil, change_threshold: nil, webhook_url: nil, webhook_secret: nil, metadata: nil)
        body = { name: name, url: url, type: "extraction", config: config }
        body[:frequency] = frequency if frequency
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id
        body[:detectChanges] = detect_changes unless detect_changes.nil?
        body[:changeThreshold] = change_threshold if change_threshold
        body[:webhookUrl] = webhook_url if webhook_url
        body[:webhookSecret] = webhook_secret if webhook_secret
        body[:metadata] = metadata if metadata

        @http.post("/webdata/schedules", body)
      end

      # Update a schedule
      #
      # @param id [String] Schedule ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param name [String, nil] Schedule name
      # @param frequency [String, nil] Frequency
      # @param config [Hash, nil] Configuration
      # @param is_active [Boolean, nil] Active status
      # @param detect_changes [Boolean, nil] Detect changes
      # @param change_threshold [Numeric, nil] Change threshold
      # @param webhook_url [String, nil] Webhook URL
      # @param webhook_secret [String, nil] Webhook secret
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Success response
      def update_schedule(id:, environment: nil, project_id: nil, name: nil, frequency: nil,
                          config: nil, is_active: nil, detect_changes: nil, change_threshold: nil,
                          webhook_url: nil, webhook_secret: nil, metadata: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        body = {}
        body[:name] = name if name
        body[:frequency] = frequency if frequency
        body[:config] = config if config
        body[:isActive] = is_active unless is_active.nil?
        body[:detectChanges] = detect_changes unless detect_changes.nil?
        body[:changeThreshold] = change_threshold if change_threshold
        body[:webhookUrl] = webhook_url unless webhook_url.nil?
        body[:webhookSecret] = webhook_secret unless webhook_secret.nil?
        body[:metadata] = metadata if metadata

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.post("/webdata/schedules/#{id}#{query}", body)
      end

      # Get a schedule by ID
      #
      # @param id [String] Schedule ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Schedule details
      def get_schedule(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        convert_schedule_dates(@http.get("/webdata/schedules/#{id}#{query}"))
      end

      # List schedules
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param is_active [Boolean, nil] Active filter
      # @param limit [Integer, nil] Maximum results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of schedules
      def list_schedules(environment: nil, project_id: nil, is_active: nil, limit: nil, cursor: nil)
        params = { type: "extraction" }
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:isActive] = is_active.to_s unless is_active.nil?
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/schedules#{query}")
        response["items"] = response["items"].map { |i| convert_schedule_dates(i) } if response["items"]
        response
      end

      # Delete a schedule
      #
      # @param id [String] Schedule ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def delete_schedule(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.delete_with_body("/webdata/schedules/#{id}#{query}", {
          id: id,
          environment: environment,
          projectId: project_id
        }.compact)
      end

      # Toggle a schedule
      #
      # @param id [String] Schedule ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Toggle result
      def toggle_schedule(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.post("/webdata/schedules/#{id}/toggle#{query}", {})
      end

      # Get usage statistics
      #
      # @param environment [String, nil] Environment
      # @param period_start [String, nil] Period start
      # @param period_end [String, nil] Period end
      # @return [Hash] Usage statistics
      def get_usage(environment: nil, period_start: nil, period_end: nil)
        params = {}
        params[:environment] = environment if environment
        params[:periodStart] = period_start if period_start
        params[:periodEnd] = period_end if period_end

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/usage#{query}")
        convert_usage_dates(response)
      end

      # Get daily usage breakdown
      #
      # @param environment [String, nil] Environment
      # @param period_start [String, nil] Period start
      # @param period_end [String, nil] Period end
      # @return [Hash] Daily usage data
      def get_usage_daily(environment: nil, period_start: nil, period_end: nil)
        params = {}
        params[:environment] = environment if environment
        params[:periodStart] = period_start if period_start
        params[:periodEnd] = period_end if period_end

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/webdata/usage/daily#{query}")
      end

      private

      def convert_dates(extraction)
        return extraction unless extraction.is_a?(Hash)

        %w[createdAt completedAt].each do |field|
          extraction[field] = Time.parse(extraction[field]) if extraction[field].is_a?(String)
        end
        extraction
      end

      def convert_batch_job_dates(job)
        return job unless job.is_a?(Hash)

        %w[createdAt startedAt completedAt].each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end

      def convert_schedule_dates(schedule)
        return schedule unless schedule.is_a?(Hash)

        %w[createdAt updatedAt lastRunAt nextRunAt].each do |field|
          schedule[field] = Time.parse(schedule[field]) if schedule[field].is_a?(String)
        end
        schedule
      end

      def convert_usage_dates(usage)
        return usage unless usage.is_a?(Hash)

        %w[periodStart periodEnd].each do |field|
          usage[field] = Time.parse(usage[field]) if usage[field].is_a?(String)
        end
        usage
      end
    end
  end
end
