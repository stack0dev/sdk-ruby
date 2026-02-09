# frozen_string_literal: true

require "time"
require "uri"

module Stack0
  module Screenshots
    # Screenshots client for capturing webpage screenshots
    class Client
      include Polling

      def initialize(http)
        @http = http
      end

      # Capture a screenshot of a URL
      #
      # @param url [String] URL to capture
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param format [String, nil] Output format (png, jpeg, webp, pdf)
      # @param quality [Integer, nil] Quality (1-100)
      # @param full_page [Boolean, nil] Capture full page
      # @param device_type [String, nil] Device type (desktop, tablet, mobile)
      # @param viewport_width [Integer, nil] Viewport width
      # @param viewport_height [Integer, nil] Viewport height
      # @param device_scale_factor [Numeric, nil] Device scale factor
      # @param wait_for_selector [String, nil] CSS selector to wait for
      # @param wait_for_timeout [Integer, nil] Timeout in milliseconds
      # @param block_ads [Boolean, nil] Block ads
      # @param block_cookie_banners [Boolean, nil] Block cookie banners
      # @param block_chat_widgets [Boolean, nil] Block chat widgets
      # @param block_trackers [Boolean, nil] Block trackers
      # @param block_urls [Array<String>, nil] URLs to block
      # @param block_resources [Array<String>, nil] Resource types to block
      # @param dark_mode [Boolean, nil] Enable dark mode
      # @param custom_css [String, nil] Custom CSS
      # @param custom_js [String, nil] Custom JavaScript
      # @param headers [Hash, nil] Custom headers
      # @param cookies [Array<Hash>, nil] Cookies to set
      # @param selector [String, nil] Element selector to capture
      # @param hide_selectors [Array<String>, nil] Selectors to hide
      # @param click_selector [String, nil] Selector to click
      # @param omit_background [Boolean, nil] Omit background
      # @param user_agent [String, nil] Custom user agent
      # @param clip [Hash, nil] Clip region
      # @param thumbnail_width [Integer, nil] Thumbnail width
      # @param thumbnail_height [Integer, nil] Thumbnail height
      # @param cache_key [String, nil] Cache key
      # @param cache_ttl [Integer, nil] Cache TTL
      # @param webhook_url [String, nil] Webhook URL
      # @param webhook_secret [String, nil] Webhook secret
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Screenshot job with ID and status
      def capture(url:, environment: nil, project_id: nil, format: nil, quality: nil, full_page: nil,
                  device_type: nil, viewport_width: nil, viewport_height: nil, device_scale_factor: nil,
                  wait_for_selector: nil, wait_for_timeout: nil, block_ads: nil, block_cookie_banners: nil,
                  block_chat_widgets: nil, block_trackers: nil, block_urls: nil, block_resources: nil,
                  dark_mode: nil, custom_css: nil, custom_js: nil, headers: nil, cookies: nil,
                  selector: nil, hide_selectors: nil, click_selector: nil, omit_background: nil,
                  user_agent: nil, clip: nil, thumbnail_width: nil, thumbnail_height: nil,
                  cache_key: nil, cache_ttl: nil, webhook_url: nil, webhook_secret: nil, metadata: nil)
        body = { url: url }
        body[:environment] = environment if environment
        body[:projectId] = project_id if project_id
        body[:format] = format if format
        body[:quality] = quality if quality
        body[:fullPage] = full_page unless full_page.nil?
        body[:deviceType] = device_type if device_type
        body[:viewportWidth] = viewport_width if viewport_width
        body[:viewportHeight] = viewport_height if viewport_height
        body[:deviceScaleFactor] = device_scale_factor if device_scale_factor
        body[:waitForSelector] = wait_for_selector if wait_for_selector
        body[:waitForTimeout] = wait_for_timeout if wait_for_timeout
        body[:blockAds] = block_ads unless block_ads.nil?
        body[:blockCookieBanners] = block_cookie_banners unless block_cookie_banners.nil?
        body[:blockChatWidgets] = block_chat_widgets unless block_chat_widgets.nil?
        body[:blockTrackers] = block_trackers unless block_trackers.nil?
        body[:blockUrls] = block_urls if block_urls
        body[:blockResources] = block_resources if block_resources
        body[:darkMode] = dark_mode unless dark_mode.nil?
        body[:customCss] = custom_css if custom_css
        body[:customJs] = custom_js if custom_js
        body[:headers] = headers if headers
        body[:cookies] = cookies if cookies
        body[:selector] = selector if selector
        body[:hideSelectors] = hide_selectors if hide_selectors
        body[:clickSelector] = click_selector if click_selector
        body[:omitBackground] = omit_background unless omit_background.nil?
        body[:userAgent] = user_agent if user_agent
        body[:clip] = clip if clip
        body[:thumbnailWidth] = thumbnail_width if thumbnail_width
        body[:thumbnailHeight] = thumbnail_height if thumbnail_height
        body[:cacheKey] = cache_key if cache_key
        body[:cacheTtl] = cache_ttl if cache_ttl
        body[:webhookUrl] = webhook_url if webhook_url
        body[:webhookSecret] = webhook_secret if webhook_secret
        body[:metadata] = metadata if metadata

        @http.post("/webdata/screenshots", body)
      end

      # Get a screenshot by ID
      #
      # @param id [String] Screenshot ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Screenshot details
      def get(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        convert_dates(@http.get("/webdata/screenshots/#{id}#{query}"))
      end

      # List screenshots with pagination and filters
      #
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param status [String, nil] Status filter
      # @param url [String, nil] URL filter
      # @param limit [Integer, nil] Maximum results
      # @param cursor [String, nil] Pagination cursor
      # @return [Hash] Paginated list of screenshots
      def list(environment: nil, project_id: nil, status: nil, url: nil, limit: nil, cursor: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id
        params[:status] = status if status
        params[:url] = url if url
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/webdata/screenshots#{query}")
        response["items"] = response["items"].map { |i| convert_dates(i) } if response["items"]
        response
      end

      # Delete a screenshot
      #
      # @param id [String] Screenshot ID
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @return [Hash] Success response
      def delete(id:, environment: nil, project_id: nil)
        params = {}
        params[:environment] = environment if environment
        params[:projectId] = project_id if project_id

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.delete_with_body("/webdata/screenshots/#{id}#{query}", {
          id: id,
          environment: environment,
          projectId: project_id
        }.compact)
      end

      # Capture a screenshot and wait for completion
      #
      # @param poll_interval [Integer] Poll interval in seconds
      # @param timeout [Integer] Timeout in seconds
      # @param capture_options [Hash] Options passed to capture
      # @return [Hash] Completed screenshot
      def capture_and_wait(poll_interval: 1, timeout: 60, **capture_options)
        response = capture(**capture_options)
        id = response["id"]
        start_time = Time.now

        loop do
          screenshot = get(
            id: id,
            environment: capture_options[:environment],
            project_id: capture_options[:project_id]
          )

          return screenshot if screenshot["status"] == "completed"

          if screenshot["status"] == "failed"
            raise Error, screenshot["error"] || "Screenshot failed"
          end

          if Time.now - start_time > timeout
            raise TimeoutError, "Screenshot timed out"
          end

          sleep(poll_interval)
        end
      end

      # Create a batch screenshot job
      #
      # @param urls [Array<String>] URLs to capture
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param name [String, nil] Job name
      # @param config [Hash, nil] Screenshot configuration
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

        @http.post("/webdata/batch/screenshots", body)
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
        params = { type: "screenshot" }
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

      # Create a scheduled screenshot job
      #
      # @param name [String] Schedule name
      # @param url [String] URL to capture
      # @param frequency [String] Frequency (hourly, daily, weekly, monthly)
      # @param config [Hash] Screenshot configuration
      # @param environment [String, nil] Environment
      # @param project_id [String, nil] Project ID
      # @param detect_changes [Boolean, nil] Detect changes
      # @param change_threshold [Numeric, nil] Change threshold
      # @param webhook_url [String, nil] Webhook URL
      # @param webhook_secret [String, nil] Webhook secret
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Created schedule
      def create_schedule(name:, url:, frequency: nil, config:, environment: nil, project_id: nil,
                          detect_changes: nil, change_threshold: nil, webhook_url: nil, webhook_secret: nil, metadata: nil)
        body = { name: name, url: url, type: "screenshot", config: config }
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
        params = { type: "screenshot" }
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

      private

      def convert_dates(screenshot)
        return screenshot unless screenshot.is_a?(Hash)

        %w[createdAt completedAt].each do |field|
          screenshot[field] = Time.parse(screenshot[field]) if screenshot[field].is_a?(String)
        end
        screenshot
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
    end
  end
end
