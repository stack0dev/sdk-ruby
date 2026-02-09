# frozen_string_literal: true

require "time"
require "uri"

module Stack0
  module Webdata
    # Webdata client for screenshots and extractions (deprecated - use Screenshots and Extraction)
    class Client
      def initialize(http)
        @http = http
      end

      # Capture a screenshot of a URL
      #
      # @param url [String] URL to capture
      # @param format [String, nil] Image format (png, jpeg, webp)
      # @param full_page [Boolean, nil] Capture full page
      # @param device_type [String, nil] Device type (desktop, mobile, tablet)
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Screenshot creation response with id and status
      def screenshot(url:, format: nil, full_page: nil, device_type: nil, environment: nil, project_id: nil)
        body = { url: url }
        body[:format] = format if format
        body[:fullPage] = full_page unless full_page.nil?
        body[:deviceType] = device_type if device_type
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id

        @http.post("/webdata/screenshots", body)
      end

      # Get a screenshot by ID
      #
      # @param id [String] Screenshot ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Screenshot details
      def get_screenshot(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/screenshots/#{id}#{query}")
        convert_screenshot_dates(response)
      end

      # List screenshots with pagination and filters
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param status [String, nil] Status filter
      # @param url [String, nil] URL filter
      # @param limit [Integer, nil] Maximum number of results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of screenshots
      def list_screenshots(environment: nil, project_id: nil, status: nil, url: nil, limit: nil, cursor: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:status] = status if status
        params[:url] = url if url
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/screenshots#{query}")
        response["items"] = response["items"].map { |i| convert_screenshot_dates(i) } if response["items"]
        response
      end

      # Delete a screenshot
      #
      # @param id [String] Screenshot ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def delete_screenshot(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.delete("/webdata/screenshots/#{id}#{query}")
      end

      # Capture a screenshot and wait for completion
      #
      # @param url [String] URL to capture
      # @param format [String, nil] Image format
      # @param full_page [Boolean, nil] Capture full page
      # @param device_type [String, nil] Device type
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param poll_interval [Integer] Polling interval in seconds (default: 1)
      # @param timeout [Integer] Timeout in seconds (default: 60)
      # @return [Hash] Completed screenshot
      def screenshot_and_wait(url:, format: nil, full_page: nil, device_type: nil,
                              environment: nil, project_id: nil, poll_interval: 1, timeout: 60)
        start_time = Time.now
        result = screenshot(
          url: url,
          format: format,
          full_page: full_page,
          device_type: device_type,
          environment: environment,
          project_id: project_id
        )

        while Time.now - start_time < timeout
          screenshot = get_screenshot(id: result["id"], environment: environment, project_id: project_id)

          if screenshot["status"] == "completed" || screenshot["status"] == "failed"
            raise Error, screenshot["error"] || "Screenshot failed" if screenshot["status"] == "failed"

            return screenshot
          end

          sleep(poll_interval)
        end

        raise TimeoutError, "Screenshot timed out"
      end

      # Extract content from a URL
      #
      # @param url [String] URL to extract from
      # @param mode [String, nil] Extraction mode (markdown, html, text)
      # @param include_metadata [Boolean, nil] Include page metadata
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Extraction creation response with id and status
      def extract(url:, mode: nil, include_metadata: nil, environment: nil, project_id: nil)
        body = { url: url }
        body[:mode] = mode if mode
        body[:includeMetadata] = include_metadata unless include_metadata.nil?
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id

        @http.post("/webdata/extractions", body)
      end

      # Get an extraction by ID
      #
      # @param id [String] Extraction ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Extraction details
      def get_extraction(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/extractions/#{id}#{query}")
        convert_extraction_dates(response)
      end

      # List extractions with pagination and filters
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param status [String, nil] Status filter
      # @param url [String, nil] URL filter
      # @param limit [Integer, nil] Maximum number of results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of extractions
      def list_extractions(environment: nil, project_id: nil, status: nil, url: nil, limit: nil, cursor: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:status] = status if status
        params[:url] = url if url
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/extractions#{query}")
        response["items"] = response["items"].map { |i| convert_extraction_dates(i) } if response["items"]
        response
      end

      # Delete an extraction
      #
      # @param id [String] Extraction ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def delete_extraction(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.delete("/webdata/extractions/#{id}#{query}")
      end

      # Extract content and wait for completion
      #
      # @param url [String] URL to extract from
      # @param mode [String, nil] Extraction mode
      # @param include_metadata [Boolean, nil] Include page metadata
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param poll_interval [Integer] Polling interval in seconds (default: 1)
      # @param timeout [Integer] Timeout in seconds (default: 60)
      # @return [Hash] Completed extraction
      def extract_and_wait(url:, mode: nil, include_metadata: nil, environment: nil,
                           project_id: nil, poll_interval: 1, timeout: 60)
        start_time = Time.now
        result = extract(
          url: url,
          mode: mode,
          include_metadata: include_metadata,
          environment: environment,
          project_id: project_id
        )

        while Time.now - start_time < timeout
          extraction = get_extraction(id: result["id"], environment: environment, project_id: project_id)

          if extraction["status"] == "completed" || extraction["status"] == "failed"
            raise Error, extraction["error"] || "Extraction failed" if extraction["status"] == "failed"

            return extraction
          end

          sleep(poll_interval)
        end

        raise TimeoutError, "Extraction timed out"
      end

      # Create a scheduled screenshot or extraction job
      #
      # @param name [String] Schedule name
      # @param url [String] URL to process
      # @param type [String] Type (screenshot or extraction)
      # @param frequency [String] Frequency (hourly, daily, weekly)
      # @param config [Hash, nil] Configuration options
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Created schedule
      def create_schedule(name:, url:, type:, frequency:, config: nil, environment: nil, project_id: nil)
        body = { name: name, url: url, type: type, frequency: frequency }
        body[:config] = config if config
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id

        @http.post("/webdata/schedules", body)
      end

      # Update a schedule
      #
      # @param id [String] Schedule ID
      # @param name [String, nil] Schedule name
      # @param frequency [String, nil] Frequency
      # @param is_active [Boolean, nil] Whether schedule is active
      # @param config [Hash, nil] Configuration options
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def update_schedule(id:, name: nil, frequency: nil, is_active: nil, config: nil,
                          environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"

        body = {}
        body[:name] = name if name
        body[:frequency] = frequency if frequency
        body[:isActive] = is_active unless is_active.nil?
        body[:config] = config if config

        @http.patch("/webdata/schedules/#{id}#{query}", body)
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
        response = @http.get("/webdata/schedules/#{id}#{query}")
        convert_schedule_dates(response)
      end

      # List schedules with pagination and filters
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param type [String, nil] Type filter
      # @param is_active [Boolean, nil] Active status filter
      # @param limit [Integer, nil] Maximum number of results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of schedules
      def list_schedules(environment: nil, project_id: nil, type: nil, is_active: nil, limit: nil, cursor: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:type] = type if type
        params[:isActive] = is_active unless is_active.nil?
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
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
        @http.delete("/webdata/schedules/#{id}#{query}")
      end

      # Toggle a schedule on or off
      #
      # @param id [String] Schedule ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Toggle result with is_active
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
      # @param period_start [String, nil] Period start (ISO8601)
      # @param period_end [String, nil] Period end (ISO8601)
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

      # Create a batch screenshot job for multiple URLs
      #
      # @param urls [Array<String>] URLs to capture
      # @param config [Hash, nil] Screenshot configuration
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Batch job creation response
      def batch_screenshots(urls:, config: nil, environment: nil, project_id: nil)
        body = { urls: urls }
        body[:config] = config if config
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id

        @http.post("/webdata/batch/screenshots", body)
      end

      # Create a batch extraction job for multiple URLs
      #
      # @param urls [Array<String>] URLs to extract
      # @param config [Hash, nil] Extraction configuration
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Batch job creation response
      def batch_extractions(urls:, config: nil, environment: nil, project_id: nil)
        body = { urls: urls }
        body[:config] = config if config
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id

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
        response = @http.get("/webdata/batch/#{id}#{query}")
        convert_batch_job_dates(response)
      end

      # List batch jobs with pagination and filters
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param status [String, nil] Status filter
      # @param type [String, nil] Type filter
      # @param limit [Integer, nil] Maximum number of results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of batch jobs
      def list_batch_jobs(environment: nil, project_id: nil, status: nil, type: nil, limit: nil, cursor: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:status] = status if status
        params[:type] = type if type
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
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

      # Create a batch screenshot job and wait for completion
      #
      # @param urls [Array<String>] URLs to capture
      # @param config [Hash, nil] Screenshot configuration
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param poll_interval [Integer] Polling interval in seconds (default: 2)
      # @param timeout [Integer] Timeout in seconds (default: 300)
      # @return [Hash] Completed batch job
      def batch_screenshots_and_wait(urls:, config: nil, environment: nil, project_id: nil,
                                     poll_interval: 2, timeout: 300)
        start_time = Time.now
        result = batch_screenshots(urls: urls, config: config, environment: environment, project_id: project_id)

        while Time.now - start_time < timeout
          job = get_batch_job(id: result["id"], environment: environment, project_id: project_id)

          if %w[completed failed cancelled].include?(job["status"])
            return job
          end

          sleep(poll_interval)
        end

        raise TimeoutError, "Batch job timed out"
      end

      # Create a batch extraction job and wait for completion
      #
      # @param urls [Array<String>] URLs to extract
      # @param config [Hash, nil] Extraction configuration
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param poll_interval [Integer] Polling interval in seconds (default: 2)
      # @param timeout [Integer] Timeout in seconds (default: 300)
      # @return [Hash] Completed batch job
      def batch_extractions_and_wait(urls:, config: nil, environment: nil, project_id: nil,
                                     poll_interval: 2, timeout: 300)
        start_time = Time.now
        result = batch_extractions(urls: urls, config: config, environment: environment, project_id: project_id)

        while Time.now - start_time < timeout
          job = get_batch_job(id: result["id"], environment: environment, project_id: project_id)

          if %w[completed failed cancelled].include?(job["status"])
            return job
          end

          sleep(poll_interval)
        end

        raise TimeoutError, "Batch job timed out"
      end

      private

      def convert_screenshot_dates(screenshot)
        return screenshot unless screenshot.is_a?(Hash)

        date_fields = %w[createdAt completedAt]
        date_fields.each do |field|
          screenshot[field] = Time.parse(screenshot[field]) if screenshot[field].is_a?(String)
        end
        screenshot
      end

      def convert_extraction_dates(extraction)
        return extraction unless extraction.is_a?(Hash)

        date_fields = %w[createdAt completedAt]
        date_fields.each do |field|
          extraction[field] = Time.parse(extraction[field]) if extraction[field].is_a?(String)
        end
        extraction
      end

      def convert_schedule_dates(schedule)
        return schedule unless schedule.is_a?(Hash)

        date_fields = %w[createdAt updatedAt lastRunAt nextRunAt]
        date_fields.each do |field|
          schedule[field] = Time.parse(schedule[field]) if schedule[field].is_a?(String)
        end
        schedule
      end

      def convert_usage_dates(usage)
        return usage unless usage.is_a?(Hash)

        date_fields = %w[periodStart periodEnd]
        date_fields.each do |field|
          usage[field] = Time.parse(usage[field]) if usage[field].is_a?(String)
        end
        usage
      end

      def convert_batch_job_dates(job)
        return job unless job.is_a?(Hash)

        date_fields = %w[createdAt startedAt completedAt]
        date_fields.each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end
    end
  end
end
