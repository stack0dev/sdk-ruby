# frozen_string_literal: true

require "time"
require "uri"

module Stack0
  module CDN
    # Allowed widths that match the CloudFront url-rewriter configuration
    ALLOWED_WIDTHS = [256, 384, 640, 750, 828, 1080, 1200, 1920, 2048, 3840].freeze

    # CDN client for managing assets, folders, and video transcoding
    class Client
      def initialize(http, cdn_url: nil)
        @http = http
        @cdn_url = cdn_url
      end

      # Generate a presigned URL for uploading a file
      #
      # @param project_slug [String] Project slug
      # @param filename [String] File name
      # @param mime_type [String] MIME type
      # @param size [Integer] File size in bytes
      # @param folder [String, nil] Target folder
      # @param metadata [Hash, nil] Custom metadata
      # @param watermark [Hash, nil] Watermark configuration
      # @return [Hash] Upload URL and asset ID
      def get_upload_url(project_slug:, filename:, mime_type:, size:, folder: nil, metadata: nil, watermark: nil)
        body = {
          projectSlug: project_slug,
          filename: filename,
          mimeType: mime_type,
          size: size
        }
        body[:folder] = folder if folder
        body[:metadata] = metadata if metadata
        body[:watermark] = watermark if watermark

        response = @http.post("/cdn/upload", body)
        response["expiresAt"] = Time.parse(response["expiresAt"]) if response["expiresAt"].is_a?(String)
        response
      end

      # Confirm that an upload has completed
      #
      # @param asset_id [String] Asset ID
      # @return [Hash] Confirmed asset
      def confirm_upload(asset_id)
        convert_asset_dates(@http.post("/cdn/upload/#{asset_id}/confirm", {}))
      end

      # Get an asset by ID
      #
      # @param id [String] Asset ID
      # @return [Hash] Asset details
      def get(id)
        convert_asset_dates(@http.get("/cdn/assets/#{id}"))
      end

      # Update asset metadata
      #
      # @param id [String] Asset ID
      # @param filename [String, nil] New filename
      # @param folder [String, nil] New folder
      # @param tags [Array<String>, nil] New tags
      # @param alt [String, nil] Alt text
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Updated asset
      def update(id:, filename: nil, folder: nil, tags: nil, alt: nil, metadata: nil)
        body = {}
        body[:filename] = filename if filename
        body[:folder] = folder if folder
        body[:tags] = tags if tags
        body[:alt] = alt if alt
        body[:metadata] = metadata if metadata

        convert_asset_dates(@http.patch("/cdn/assets/#{id}", body))
      end

      # Delete an asset
      #
      # @param id [String] Asset ID
      # @return [Hash] Success response
      def delete(id)
        @http.delete_with_body("/cdn/assets/#{id}", { id: id })
      end

      # Delete multiple assets
      #
      # @param ids [Array<String>] Asset IDs
      # @return [Hash] Delete result with count
      def delete_many(ids)
        @http.post("/cdn/assets/delete", { ids: ids })
      end

      # List assets with filters and pagination
      #
      # @param project_slug [String] Project slug
      # @param folder [String, nil] Folder filter
      # @param type [String, nil] Asset type filter
      # @param status [String, nil] Status filter
      # @param search [String, nil] Search query
      # @param tags [Array<String>, nil] Tags filter
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of assets
      def list(project_slug:, folder: nil, type: nil, status: nil, search: nil,
               tags: nil, sort_by: nil, sort_order: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:folder] = folder if folder
        params[:type] = type if type
        params[:status] = status if status
        params[:search] = search if search
        params[:tags] = tags.join(",") if tags
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        response = @http.get("/cdn/assets?#{URI.encode_www_form(params)}")
        response["assets"] = response["assets"].map { |a| convert_asset_dates(a) } if response["assets"]
        response
      end

      # Move assets to a different folder
      #
      # @param asset_ids [Array<String>] Asset IDs to move
      # @param folder [String, nil] Target folder (nil for root)
      # @return [Hash] Move result with count
      def move(asset_ids:, folder:)
        @http.post("/cdn/assets/move", { assetIds: asset_ids, folder: folder })
      end

      # Get a transformed image URL (client-side, no API call)
      #
      # @param asset_url_or_s3_key [String] Asset CDN URL or S3 key
      # @param options [Hash] Transform options
      # @return [String] Transform URL
      def get_transform_url(asset_url_or_s3_key, options = {})
        if asset_url_or_s3_key.start_with?("http://", "https://")
          uri = URI.parse(asset_url_or_s3_key)
          base_url = "#{uri.scheme}://#{uri.host}#{uri.path}"
        elsif @cdn_url
          cdn_base = @cdn_url.end_with?("/") ? @cdn_url[0..-2] : @cdn_url
          base_url = "#{cdn_base}/#{asset_url_or_s3_key}"
        else
          raise Error, "get_transform_url requires either a full URL or cdn_url to be configured"
        end

        query = build_transform_query(options)
        query.empty? ? base_url : "#{base_url}?#{query}"
      end

      # Get folder tree for navigation
      #
      # @param project_slug [String] Project slug
      # @param max_depth [Integer, nil] Maximum depth
      # @return [Array<Hash>] Folder tree
      def get_folder_tree(project_slug:, max_depth: nil)
        params = { projectSlug: project_slug }
        params[:maxDepth] = max_depth if max_depth

        response = @http.get("/cdn/folders/tree?#{URI.encode_www_form(params)}")
        response["tree"]
      end

      # Create a new folder
      #
      # @param project_slug [String] Project slug
      # @param name [String] Folder name
      # @param parent_id [String, nil] Parent folder ID
      # @return [Hash] Created folder
      def create_folder(project_slug:, name:, parent_id: nil)
        body = { projectSlug: project_slug, name: name }
        body[:parentId] = parent_id if parent_id

        convert_folder_dates(@http.post("/cdn/folders", body))
      end

      # Get a folder by ID
      #
      # @param id [String] Folder ID
      # @return [Hash] Folder details
      def get_folder(id)
        convert_folder_dates(@http.get("/cdn/folders/#{id}"))
      end

      # Get a folder by path
      #
      # @param path [String] Folder path
      # @return [Hash] Folder details
      def get_folder_by_path(path)
        convert_folder_dates(@http.get("/cdn/folders/path/#{URI.encode_www_form_component(path)}"))
      end

      # Update a folder
      #
      # @param id [String] Folder ID
      # @param name [String, nil] New name
      # @return [Hash] Updated folder
      def update_folder(id:, name: nil)
        body = {}
        body[:name] = name if name

        convert_folder_dates(@http.patch("/cdn/folders/#{id}", body))
      end

      # List folders
      #
      # @param parent_id [String, nil] Parent folder ID
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @param search [String, nil] Search query
      # @return [Hash] Paginated list of folders
      def list_folders(parent_id: nil, limit: nil, offset: nil, search: nil)
        params = {}
        params[:parentId] = parent_id if parent_id
        params[:limit] = limit if limit
        params[:offset] = offset if offset
        params[:search] = search if search

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/cdn/folders#{query}")
        response["folders"] = response["folders"].map { |f| convert_folder_dates(f) } if response["folders"]
        response
      end

      # Move a folder
      #
      # @param id [String] Folder ID
      # @param new_parent_id [String, nil] New parent folder ID
      # @return [Hash] Success response
      def move_folder(id:, new_parent_id:)
        @http.post("/cdn/folders/move", { id: id, newParentId: new_parent_id })
      end

      # Delete a folder
      #
      # @param id [String] Folder ID
      # @param delete_contents [Boolean] Whether to delete contents
      # @return [Hash] Success response
      def delete_folder(id, delete_contents: false)
        params = {}
        params[:deleteContents] = "true" if delete_contents

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.delete_with_body("/cdn/folders/#{id}#{query}", { id: id, deleteContents: delete_contents })
      end

      # Start a video transcoding job
      #
      # @param project_slug [String] Project slug
      # @param asset_id [String] Video asset ID
      # @param output_format [String] Output format (hls, mp4)
      # @param variants [Array<Hash>] Quality variants
      # @param watermark [Hash, nil] Watermark options
      # @param trim [Hash, nil] Trim options
      # @param webhook_url [String, nil] Webhook URL
      # @return [Hash] Transcode job
      def transcode(project_slug:, asset_id:, output_format:, variants:, watermark: nil, trim: nil, webhook_url: nil)
        body = {
          projectSlug: project_slug,
          assetId: asset_id,
          outputFormat: output_format,
          variants: variants
        }
        body[:watermark] = watermark if watermark
        body[:trim] = trim if trim
        body[:webhookUrl] = webhook_url if webhook_url

        convert_job_dates(@http.post("/cdn/video/transcode", body))
      end

      # Get a transcoding job
      #
      # @param job_id [String] Job ID
      # @return [Hash] Job details
      def get_job(job_id)
        convert_job_dates(@http.get("/cdn/video/jobs/#{job_id}"))
      end

      # List transcoding jobs
      #
      # @param project_slug [String] Project slug
      # @param asset_id [String, nil] Asset ID filter
      # @param status [String, nil] Status filter
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of jobs
      def list_jobs(project_slug:, asset_id: nil, status: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:assetId] = asset_id if asset_id
        params[:status] = status if status
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        response = @http.get("/cdn/video/jobs?#{URI.encode_www_form(params)}")
        response["jobs"] = response["jobs"].map { |j| convert_job_dates(j) } if response["jobs"]
        response
      end

      # Cancel a transcoding job
      #
      # @param job_id [String] Job ID
      # @return [Hash] Success response
      def cancel_job(job_id)
        @http.post("/cdn/video/jobs/#{job_id}/cancel", {})
      end

      # Get streaming URLs for a transcoded video
      #
      # @param asset_id [String] Asset ID
      # @return [Hash] Streaming URLs
      def get_streaming_urls(asset_id)
        @http.get("/cdn/video/stream/#{asset_id}")
      end

      # Generate a thumbnail from a video
      #
      # @param asset_id [String] Asset ID
      # @param timestamp [Numeric] Timestamp in seconds
      # @param width [Integer, nil] Thumbnail width
      # @param format [String, nil] Output format
      # @return [Hash] Thumbnail details
      def get_thumbnail(asset_id:, timestamp:, width: nil, format: nil)
        params = { timestamp: timestamp }
        params[:width] = width if width
        params[:format] = format if format

        @http.get("/cdn/video/thumbnail/#{asset_id}?#{URI.encode_www_form(params)}")
      end

      # Regenerate a thumbnail
      #
      # @param asset_id [String] Asset ID
      # @param timestamp [Numeric] Timestamp in seconds
      # @param width [Integer, nil] Thumbnail width
      # @param format [String, nil] Output format
      # @return [Hash] Regeneration result
      def regenerate_thumbnail(asset_id:, timestamp:, width: nil, format: nil)
        body = { assetId: asset_id, timestamp: timestamp }
        body[:width] = width if width
        body[:format] = format if format

        @http.post("/cdn/video/thumbnail/regenerate", body)
      end

      # List thumbnails for a video
      #
      # @param asset_id [String] Asset ID
      # @return [Hash] List of thumbnails
      def list_thumbnails(asset_id)
        @http.get("/cdn/video/#{asset_id}/thumbnails")
      end

      # Extract audio from a video
      #
      # @param project_slug [String] Project slug
      # @param asset_id [String] Asset ID
      # @param format [String] Output format
      # @param bitrate [Integer, nil] Audio bitrate
      # @return [Hash] Extraction job
      def extract_audio(project_slug:, asset_id:, format:, bitrate: nil)
        body = { projectSlug: project_slug, assetId: asset_id, format: format }
        body[:bitrate] = bitrate if bitrate

        @http.post("/cdn/video/extract-audio", body)
      end

      # Generate an animated GIF from a video
      #
      # @param project_slug [String] Project slug
      # @param asset_id [String] Asset ID
      # @param start_time [Numeric, nil] Start time in seconds
      # @param duration [Numeric, nil] Duration in seconds
      # @param width [Integer, nil] Output width
      # @param fps [Integer, nil] Frames per second
      # @param optimize_palette [Boolean, nil] Optimize palette
      # @return [Hash] GIF job
      def generate_gif(project_slug:, asset_id:, start_time: nil, duration: nil, width: nil, fps: nil, optimize_palette: nil)
        body = { projectSlug: project_slug, assetId: asset_id }
        body[:startTime] = start_time if start_time
        body[:duration] = duration if duration
        body[:width] = width if width
        body[:fps] = fps if fps
        body[:optimizePalette] = optimize_palette unless optimize_palette.nil?

        convert_gif_dates(@http.post("/cdn/video/gif", body))
      end

      # Get a GIF by ID
      #
      # @param gif_id [String] GIF ID
      # @return [Hash, nil] GIF details
      def get_gif(gif_id)
        response = @http.get("/cdn/video/gif/#{gif_id}")
        response ? convert_gif_dates(response) : nil
      end

      # List GIFs for a video
      #
      # @param asset_id [String] Asset ID
      # @return [Array<Hash>] List of GIFs
      def list_gifs(asset_id:)
        response = @http.get("/cdn/video/#{asset_id}/gifs")
        response.map { |g| convert_gif_dates(g) }
      end

      # Get private upload URL
      #
      # @param project_slug [String] Project slug
      # @param filename [String] File name
      # @param mime_type [String] MIME type
      # @param size [Integer] File size
      # @param folder [String, nil] Target folder
      # @param description [String, nil] File description
      # @param metadata [Hash, nil] Custom metadata
      # @return [Hash] Upload URL and file ID
      def get_private_upload_url(project_slug:, filename:, mime_type:, size:, folder: nil, description: nil, metadata: nil)
        body = {
          projectSlug: project_slug,
          filename: filename,
          mimeType: mime_type,
          size: size
        }
        body[:folder] = folder if folder
        body[:description] = description if description
        body[:metadata] = metadata if metadata

        response = @http.post("/cdn/private/upload", body)
        response["expiresAt"] = Time.parse(response["expiresAt"]) if response["expiresAt"].is_a?(String)
        response
      end

      # Confirm private file upload
      #
      # @param file_id [String] File ID
      # @return [Hash] Confirmed file
      def confirm_private_upload(file_id)
        convert_private_file_dates(@http.post("/cdn/private/upload/#{file_id}/confirm", {}))
      end

      # Get private download URL
      #
      # @param file_id [String] File ID
      # @param expires_in [Integer, nil] Expiration time in seconds
      # @return [Hash] Download URL
      def get_private_download_url(file_id:, expires_in: nil)
        body = {}
        body[:expiresIn] = expires_in if expires_in

        response = @http.post("/cdn/private/#{file_id}/download", body)
        response["expiresAt"] = Time.parse(response["expiresAt"]) if response["expiresAt"].is_a?(String)
        response
      end

      # Get a private file
      #
      # @param file_id [String] File ID
      # @return [Hash] File details
      def get_private_file(file_id)
        convert_private_file_dates(@http.get("/cdn/private/#{file_id}"))
      end

      # Update a private file
      #
      # @param file_id [String] File ID
      # @param description [String, nil] Description
      # @param folder [String, nil] Folder
      # @param tags [Array<String>, nil] Tags
      # @param metadata [Hash, nil] Metadata
      # @return [Hash] Updated file
      def update_private_file(file_id:, description: nil, folder: nil, tags: nil, metadata: nil)
        body = {}
        body[:description] = description if description
        body[:folder] = folder if folder
        body[:tags] = tags if tags
        body[:metadata] = metadata if metadata

        convert_private_file_dates(@http.patch("/cdn/private/#{file_id}", body))
      end

      # Delete a private file
      #
      # @param file_id [String] File ID
      # @return [Hash] Success response
      def delete_private_file(file_id)
        @http.delete_with_body("/cdn/private/#{file_id}", { fileId: file_id })
      end

      # Delete multiple private files
      #
      # @param file_ids [Array<String>] File IDs
      # @return [Hash] Delete result
      def delete_private_files(file_ids)
        @http.post("/cdn/private/delete", { fileIds: file_ids })
      end

      # List private files
      #
      # @param project_slug [String] Project slug
      # @param folder [String, nil] Folder filter
      # @param status [String, nil] Status filter
      # @param search [String, nil] Search query
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of files
      def list_private_files(project_slug:, folder: nil, status: nil, search: nil, sort_by: nil, sort_order: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:folder] = folder if folder
        params[:status] = status if status
        params[:search] = search if search
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        response = @http.get("/cdn/private?#{URI.encode_www_form(params)}")
        response["files"] = response["files"].map { |f| convert_private_file_dates(f) } if response["files"]
        response
      end

      # Move private files
      #
      # @param file_ids [Array<String>] File IDs
      # @param folder [String, nil] Target folder
      # @return [Hash] Move result
      def move_private_files(file_ids:, folder:)
        @http.post("/cdn/private/move", { fileIds: file_ids, folder: folder })
      end

      # Create a download bundle
      #
      # @param project_slug [String] Project slug
      # @param name [String] Bundle name
      # @param description [String, nil] Bundle description
      # @param asset_ids [Array<String>, nil] Asset IDs
      # @param private_file_ids [Array<String>, nil] Private file IDs
      # @param expires_in [Integer, nil] Expiration time in seconds
      # @return [Hash] Created bundle
      def create_bundle(project_slug:, name:, description: nil, asset_ids: nil, private_file_ids: nil, expires_in: nil)
        body = { projectSlug: project_slug, name: name }
        body[:description] = description if description
        body[:assetIds] = asset_ids if asset_ids
        body[:privateFileIds] = private_file_ids if private_file_ids
        body[:expiresIn] = expires_in if expires_in

        response = @http.post("/cdn/bundles", body)
        { "bundle" => convert_bundle_dates(response["bundle"]) }
      end

      # Get a bundle
      #
      # @param bundle_id [String] Bundle ID
      # @return [Hash] Bundle details
      def get_bundle(bundle_id)
        convert_bundle_dates(@http.get("/cdn/bundles/#{bundle_id}"))
      end

      # List bundles
      #
      # @param project_slug [String] Project slug
      # @param status [String, nil] Status filter
      # @param search [String, nil] Search query
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of bundles
      def list_bundles(project_slug:, status: nil, search: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:status] = status if status
        params[:search] = search if search
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        response = @http.get("/cdn/bundles?#{URI.encode_www_form(params)}")
        response["bundles"] = response["bundles"].map { |b| convert_bundle_dates(b) } if response["bundles"]
        response
      end

      # Get bundle download URL
      #
      # @param bundle_id [String] Bundle ID
      # @param expires_in [Integer, nil] Expiration time in seconds
      # @return [Hash] Download URL
      def get_bundle_download_url(bundle_id:, expires_in: nil)
        body = {}
        body[:expiresIn] = expires_in if expires_in

        response = @http.post("/cdn/bundles/#{bundle_id}/download", body)
        response["expiresAt"] = Time.parse(response["expiresAt"]) if response["expiresAt"].is_a?(String)
        response
      end

      # Delete a bundle
      #
      # @param bundle_id [String] Bundle ID
      # @return [Hash] Success response
      def delete_bundle(bundle_id)
        @http.delete_with_body("/cdn/bundles/#{bundle_id}", { bundleId: bundle_id })
      end

      # Get usage statistics
      #
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param period_start [Time, String, nil] Period start
      # @param period_end [Time, String, nil] Period end
      # @return [Hash] Usage statistics
      def get_usage(project_slug: nil, environment: nil, period_start: nil, period_end: nil)
        params = {}
        params[:projectSlug] = project_slug if project_slug
        params[:environment] = environment if environment
        params[:periodStart] = format_time(period_start) if period_start
        params[:periodEnd] = format_time(period_end) if period_end

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/cdn/usage#{query}")
        convert_usage_dates(response)
      end

      # Get usage history
      #
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param days [Integer, nil] Number of days
      # @param granularity [String, nil] Data granularity
      # @return [Hash] Usage history
      def get_usage_history(project_slug: nil, environment: nil, days: nil, granularity: nil)
        params = {}
        params[:projectSlug] = project_slug if project_slug
        params[:environment] = environment if environment
        params[:days] = days if days
        params[:granularity] = granularity if granularity

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/cdn/usage/history#{query}")
        response["data"] = response["data"].map { |d| convert_usage_data_point(d) } if response["data"]
        response
      end

      # Get storage breakdown
      #
      # @param project_slug [String, nil] Project slug
      # @param environment [String, nil] Environment
      # @param group_by [String, nil] Group by (type or folder)
      # @return [Hash] Storage breakdown
      def get_storage_breakdown(project_slug: nil, environment: nil, group_by: nil)
        params = {}
        params[:projectSlug] = project_slug if project_slug
        params[:environment] = environment if environment
        params[:groupBy] = group_by if group_by

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        @http.get("/cdn/usage/storage-breakdown#{query}")
      end

      # Create a merge job
      #
      # @param project_slug [String] Project slug
      # @param inputs [Array<Hash>] Input assets
      # @param audio_track [Hash, nil] Audio track configuration
      # @param output [Hash, nil] Output configuration
      # @param webhook_url [String, nil] Webhook URL
      # @return [Hash] Merge job
      def create_merge_job(project_slug:, inputs:, audio_track: nil, output: nil, webhook_url: nil)
        body = { projectSlug: project_slug, inputs: inputs }
        body[:audioTrack] = audio_track if audio_track
        body[:output] = output if output
        body[:webhookUrl] = webhook_url if webhook_url

        convert_merge_job_dates(@http.post("/cdn/video/merge", body))
      end

      # Get a merge job
      #
      # @param job_id [String] Job ID
      # @return [Hash] Merge job with output
      def get_merge_job(job_id)
        convert_merge_job_dates(@http.get("/cdn/video/merge/#{job_id}"))
      end

      # List merge jobs
      #
      # @param project_slug [String] Project slug
      # @param status [String, nil] Status filter
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of merge jobs
      def list_merge_jobs(project_slug:, status: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:status] = status if status
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        response = @http.get("/cdn/video/merge?#{URI.encode_www_form(params)}")
        response["jobs"] = response["jobs"].map { |j| convert_merge_job_dates(j) } if response["jobs"]
        response
      end

      # Cancel a merge job
      #
      # @param job_id [String] Job ID
      # @return [Hash] Success response
      def cancel_merge_job(job_id)
        @http.post("/cdn/video/merge/#{job_id}/cancel", {})
      end

      # Create an S3 import job
      #
      # @param project_slug [String] Project slug
      # @param source_bucket [String] Source S3 bucket
      # @param source_region [String] Source region
      # @param auth_type [String] Authentication type
      # @param environment [String, nil] Environment
      # @param source_prefix [String, nil] Source prefix
      # @param access_key_id [String, nil] AWS access key ID
      # @param secret_access_key [String, nil] AWS secret access key
      # @param role_arn [String, nil] IAM role ARN
      # @param external_id [String, nil] External ID
      # @param path_mode [String, nil] Path mode
      # @param target_folder [String, nil] Target folder
      # @param notify_email [String, nil] Notification email
      # @return [Hash] Import job
      def create_import(project_slug:, source_bucket:, source_region:, auth_type:, environment: nil,
                        source_prefix: nil, access_key_id: nil, secret_access_key: nil, role_arn: nil,
                        external_id: nil, path_mode: nil, target_folder: nil, notify_email: nil)
        body = {
          projectSlug: project_slug,
          sourceBucket: source_bucket,
          sourceRegion: source_region,
          authType: auth_type
        }
        body[:environment] = environment if environment
        body[:sourcePrefix] = source_prefix if source_prefix
        body[:accessKeyId] = access_key_id if access_key_id
        body[:secretAccessKey] = secret_access_key if secret_access_key
        body[:roleArn] = role_arn if role_arn
        body[:externalId] = external_id if external_id
        body[:pathMode] = path_mode if path_mode
        body[:targetFolder] = target_folder if target_folder
        body[:notifyEmail] = notify_email if notify_email

        response = @http.post("/cdn/imports", body)
        response["createdAt"] = Time.parse(response["createdAt"]) if response["createdAt"].is_a?(String)
        response
      end

      # Get an import job
      #
      # @param import_id [String] Import ID
      # @return [Hash, nil] Import job
      def get_import(import_id)
        response = @http.get("/cdn/imports/#{import_id}")
        response ? convert_import_job_dates(response) : nil
      end

      # List import jobs
      #
      # @param project_slug [String] Project slug
      # @param environment [String, nil] Environment
      # @param status [String, nil] Status filter
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of imports
      def list_imports(project_slug:, environment: nil, status: nil, sort_by: nil, sort_order: nil, limit: nil, offset: nil)
        params = { projectSlug: project_slug }
        params[:environment] = environment if environment
        params[:status] = status if status
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        response = @http.get("/cdn/imports?#{URI.encode_www_form(params)}")
        response["imports"] = response["imports"].map { |i| convert_import_summary_dates(i) } if response["imports"]
        response
      end

      # Cancel an import job
      #
      # @param import_id [String] Import ID
      # @return [Hash] Cancel result
      def cancel_import(import_id)
        @http.post("/cdn/imports/#{import_id}/cancel", {})
      end

      # Retry failed files in an import job
      #
      # @param import_id [String] Import ID
      # @return [Hash] Retry result
      def retry_import(import_id)
        @http.post("/cdn/imports/#{import_id}/retry", {})
      end

      # List files in an import job
      #
      # @param import_id [String] Import ID
      # @param status [String, nil] Status filter
      # @param sort_by [String, nil] Sort field
      # @param sort_order [String, nil] Sort order
      # @param limit [Integer, nil] Maximum results
      # @param offset [Integer, nil] Offset for pagination
      # @return [Hash] Paginated list of files
      def list_import_files(import_id:, status: nil, sort_by: nil, sort_order: nil, limit: nil, offset: nil)
        params = {}
        params[:status] = status if status
        params[:sortBy] = sort_by if sort_by
        params[:sortOrder] = sort_order if sort_order
        params[:limit] = limit if limit
        params[:offset] = offset if offset

        query = params.empty? ? "" : "?#{URI.encode_www_form(params)}"
        response = @http.get("/cdn/imports/#{import_id}/files#{query}")
        response["files"] = response["files"].map { |f| convert_import_file_dates(f) } if response["files"]
        response
      end

      private

      def format_time(time)
        return time if time.is_a?(String)

        time.respond_to?(:iso8601) ? time.iso8601 : time.to_s
      end

      def build_transform_query(options)
        params = {}
        params[:f] = options[:format] if options[:format]
        params[:q] = options[:quality] if options[:quality]
        params[:w] = get_nearest_width(options[:width]) if options[:width]
        params[:h] = options[:height] if options[:height]
        params[:fit] = options[:fit] if options[:fit]
        params[:crop] = options[:crop] if options[:crop]
        params[:"crop-x"] = options[:crop_x] if options[:crop_x]
        params[:"crop-y"] = options[:crop_y] if options[:crop_y]
        params[:"crop-w"] = options[:crop_width] if options[:crop_width]
        params[:"crop-h"] = options[:crop_height] if options[:crop_height]
        params[:blur] = options[:blur] if options[:blur]
        params[:sharpen] = options[:sharpen] if options[:sharpen]
        params[:brightness] = options[:brightness] if options[:brightness]
        params[:saturation] = options[:saturation] if options[:saturation]
        params[:grayscale] = "true" if options[:grayscale]
        params[:rotate] = options[:rotate] if options[:rotate]
        params[:flip] = "y" if options[:flip]
        params[:flop] = "x" if options[:flop]

        params.empty? ? "" : URI.encode_www_form(params)
      end

      def get_nearest_width(width)
        ALLOWED_WIDTHS.min_by { |w| (w - width).abs }
      end

      def convert_asset_dates(asset)
        return asset unless asset.is_a?(Hash)

        %w[createdAt updatedAt].each do |field|
          asset[field] = Time.parse(asset[field]) if asset[field].is_a?(String)
        end
        asset
      end

      def convert_folder_dates(folder)
        return folder unless folder.is_a?(Hash)

        %w[createdAt updatedAt].each do |field|
          folder[field] = Time.parse(folder[field]) if folder[field].is_a?(String)
        end
        folder
      end

      def convert_job_dates(job)
        return job unless job.is_a?(Hash)

        %w[createdAt startedAt completedAt].each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end

      def convert_gif_dates(gif)
        return gif unless gif.is_a?(Hash)

        %w[createdAt completedAt].each do |field|
          gif[field] = Time.parse(gif[field]) if gif[field].is_a?(String)
        end
        gif
      end

      def convert_private_file_dates(file)
        return file unless file.is_a?(Hash)

        %w[createdAt updatedAt].each do |field|
          file[field] = Time.parse(file[field]) if file[field].is_a?(String)
        end
        file
      end

      def convert_bundle_dates(bundle)
        return bundle unless bundle.is_a?(Hash)

        %w[createdAt completedAt expiresAt].each do |field|
          bundle[field] = Time.parse(bundle[field]) if bundle[field].is_a?(String)
        end
        bundle
      end

      def convert_usage_dates(usage)
        return usage unless usage.is_a?(Hash)

        %w[periodStart periodEnd].each do |field|
          usage[field] = Time.parse(usage[field]) if usage[field].is_a?(String)
        end
        usage
      end

      def convert_usage_data_point(point)
        return point unless point.is_a?(Hash)

        point["timestamp"] = Time.parse(point["timestamp"]) if point["timestamp"].is_a?(String)
        point
      end

      def convert_merge_job_dates(job)
        return job unless job.is_a?(Hash)

        %w[createdAt updatedAt startedAt completedAt].each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end

      def convert_import_job_dates(job)
        return job unless job.is_a?(Hash)

        %w[createdAt updatedAt startedAt completedAt].each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end

      def convert_import_summary_dates(job)
        return job unless job.is_a?(Hash)

        %w[createdAt startedAt completedAt].each do |field|
          job[field] = Time.parse(job[field]) if job[field].is_a?(String)
        end
        job
      end

      def convert_import_file_dates(file)
        return file unless file.is_a?(Hash)

        %w[createdAt completedAt lastAttemptAt].each do |field|
          file[field] = Time.parse(file[field]) if file[field].is_a?(String)
        end
        file
      end
    end
  end
end
