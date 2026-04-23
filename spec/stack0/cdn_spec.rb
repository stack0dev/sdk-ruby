# frozen_string_literal: true

RSpec.describe Stack0::CDN::Client do
  let(:client) { test_client }
  let(:cdn) { client.cdn }

  describe "#get_upload_url" do
    it "generates a presigned upload URL" do
      stub_stack0_request(:post, "/cdn/upload", response_body: {
        "uploadUrl" => "https://s3.amazonaws.com/...",
        "assetId" => "asset_123",
        "expiresAt" => "2024-01-15T11:00:00Z"
      })

      result = cdn.get_upload_url(
        project_slug: "my-project",
        filename: "image.png",
        mime_type: "image/png",
        size: 12345
      )

      expect(result["assetId"]).to eq("asset_123")
      expect(result["expiresAt"]).to be_a(Time)
    end

    it "accepts additional options" do
      stub_stack0_request(:post, "/cdn/upload", response_body: {
        "uploadUrl" => "https://s3.amazonaws.com/...",
        "assetId" => "asset_456"
      })

      result = cdn.get_upload_url(
        project_slug: "my-project",
        filename: "doc.pdf",
        mime_type: "application/pdf",
        size: 50000,
        folder: "documents",
        metadata: { "category" => "reports" }
      )

      expect(result["assetId"]).to eq("asset_456")
    end
  end

  describe "#confirm_upload" do
    it "confirms an upload" do
      stub_stack0_request(:post, "/cdn/upload/asset_123/confirm", response_body: {
        "id" => "asset_123",
        "url" => "https://cdn.stack0.dev/assets/abc.png",
        "status" => "ready",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = cdn.confirm_upload("asset_123")

      expect(result["status"]).to eq("ready")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#get" do
    it "retrieves an asset by ID" do
      stub_stack0_request(:get, "/cdn/assets/asset_123", response_body: {
        "id" => "asset_123",
        "url" => "https://cdn.stack0.dev/assets/abc.png",
        "filename" => "image.png",
        "size" => 12345,
        "mimeType" => "image/png",
        "createdAt" => "2024-01-15T10:00:00Z",
        "updatedAt" => "2024-01-15T10:00:00Z"
      })

      result = cdn.get("asset_123")

      expect(result["id"]).to eq("asset_123")
      expect(result["mimeType"]).to eq("image/png")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#update" do
    it "updates an asset" do
      stub_stack0_request(:patch, "/cdn/assets/asset_123", response_body: {
        "id" => "asset_123",
        "filename" => "new-name.png",
        "alt" => "Alt text",
        "updatedAt" => "2024-01-16T10:00:00Z"
      })

      result = cdn.update(
        id: "asset_123",
        filename: "new-name.png",
        alt: "Alt text"
      )

      expect(result["filename"]).to eq("new-name.png")
    end
  end

  describe "#delete" do
    it "deletes an asset" do
      stub_request(:delete, "https://api.stack0.dev/cdn/assets/asset_123")
        .with(body: { "id" => "asset_123" }.to_json)
        .to_return(
          status: 200,
          body: { "success" => true }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = cdn.delete("asset_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#delete_many" do
    it "deletes multiple assets" do
      stub_stack0_request(:post, "/cdn/assets/delete", response_body: {
        "deleted" => 3
      })

      result = cdn.delete_many(%w[asset_1 asset_2 asset_3])

      expect(result["deleted"]).to eq(3)
    end
  end

  describe "#list" do
    it "lists assets with filters" do
      stub_stack0_request(:get, "/cdn/assets?projectSlug=my-project&limit=20", response_body: {
        "assets" => [
          { "id" => "asset_1", "url" => "https://cdn.stack0.dev/1.png", "createdAt" => "2024-01-15T10:00:00Z" },
          { "id" => "asset_2", "url" => "https://cdn.stack0.dev/2.png", "createdAt" => "2024-01-15T11:00:00Z" }
        ],
        "total" => 2
      })

      result = cdn.list(project_slug: "my-project", limit: 20)

      expect(result["assets"].length).to eq(2)
      expect(result["assets"][0]["createdAt"]).to be_a(Time)
    end

    it "filters by type and status" do
      stub_stack0_request(:get, "/cdn/assets?projectSlug=my-project&type=image&status=ready", response_body: {
        "assets" => [],
        "total" => 0
      })

      result = cdn.list(project_slug: "my-project", type: "image", status: "ready")

      expect(result["assets"]).to eq([])
    end
  end

  describe "#move" do
    it "moves assets to a folder" do
      stub_stack0_request(:post, "/cdn/assets/move", response_body: {
        "moved" => 2
      })

      result = cdn.move(asset_ids: %w[asset_1 asset_2], folder: "archive")

      expect(result["moved"]).to eq(2)
    end
  end

  describe "#get_transform_url" do
    let(:cdn_client) { Stack0::CDN::Client.new(nil, cdn_url: "https://cdn.stack0.dev") }

    it "generates a transform URL from an S3 key" do
      url = cdn_client.get_transform_url("assets/image.png", width: 800)

      expect(url).to include("cdn.stack0.dev")
      expect(url).to include("w=")
    end

    it "generates a transform URL from a full URL" do
      url = cdn_client.get_transform_url(
        "https://cdn.stack0.dev/assets/image.png",
        format: "webp",
        quality: 85
      )

      expect(url).to include("f=webp")
      expect(url).to include("q=85")
    end

    it "snaps width to allowed values" do
      url = cdn_client.get_transform_url("assets/image.png", width: 500)

      expect(url).to include("w=640")
    end
  end

  describe "#get_folder_tree" do
    it "retrieves folder tree" do
      stub_stack0_request(:get, "/cdn/folders/tree?projectSlug=my-project", response_body: {
        "tree" => [
          { "id" => "folder_1", "name" => "images", "children" => [] },
          { "id" => "folder_2", "name" => "documents", "children" => [] }
        ]
      })

      result = cdn.get_folder_tree(project_slug: "my-project")

      expect(result.length).to eq(2)
    end
  end

  describe "#create_folder" do
    it "creates a folder" do
      stub_stack0_request(:post, "/cdn/folders", response_body: {
        "id" => "folder_123",
        "name" => "images",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = cdn.create_folder(project_slug: "my-project", name: "images")

      expect(result["id"]).to eq("folder_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#list_folders" do
    it "lists folders" do
      stub_stack0_request(:get, "/cdn/folders", response_body: {
        "folders" => [
          { "id" => "folder_1", "name" => "images", "createdAt" => "2024-01-15T10:00:00Z" },
          { "id" => "folder_2", "name" => "documents", "createdAt" => "2024-01-15T11:00:00Z" }
        ]
      })

      result = cdn.list_folders

      expect(result["folders"].length).to eq(2)
      expect(result["folders"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#transcode" do
    it "starts a video transcoding job" do
      stub_stack0_request(:post, "/cdn/video/transcode", response_body: {
        "id" => "job_123",
        "status" => "pending",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = cdn.transcode(
        project_slug: "my-project",
        asset_id: "asset_123",
        output_format: "hls",
        variants: [
          { "height" => 1080, "bitrate" => 5000 },
          { "height" => 720, "bitrate" => 3000 }
        ]
      )

      expect(result["id"]).to eq("job_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#get_job" do
    it "retrieves a transcoding job" do
      stub_stack0_request(:get, "/cdn/video/jobs/job_123", response_body: {
        "id" => "job_123",
        "status" => "completed",
        "createdAt" => "2024-01-15T10:00:00Z",
        "completedAt" => "2024-01-15T10:05:00Z"
      })

      result = cdn.get_job("job_123")

      expect(result["status"]).to eq("completed")
      expect(result["completedAt"]).to be_a(Time)
    end
  end

  describe "#list_jobs" do
    it "lists transcoding jobs" do
      stub_stack0_request(:get, "/cdn/video/jobs?projectSlug=my-project", response_body: {
        "jobs" => [
          { "id" => "job_1", "status" => "completed", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "total" => 1
      })

      result = cdn.list_jobs(project_slug: "my-project")

      expect(result["jobs"].length).to eq(1)
    end
  end

  describe "#get_streaming_urls" do
    it "retrieves streaming URLs" do
      stub_stack0_request(:get, "/cdn/video/stream/asset_123", response_body: {
        "hlsUrl" => "https://cdn.stack0.dev/video/abc/master.m3u8",
        "dashUrl" => "https://cdn.stack0.dev/video/abc/manifest.mpd"
      })

      result = cdn.get_streaming_urls("asset_123")

      expect(result["hlsUrl"]).to include("m3u8")
    end
  end

  describe "#generate_gif" do
    it "generates a GIF from video" do
      stub_stack0_request(:post, "/cdn/video/gif", response_body: {
        "id" => "gif_123",
        "status" => "pending",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = cdn.generate_gif(
        project_slug: "my-project",
        asset_id: "asset_123",
        start_time: 5,
        duration: 3,
        width: 320
      )

      expect(result["id"]).to eq("gif_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end

  describe "#get_private_upload_url" do
    it "generates a private upload URL" do
      stub_stack0_request(:post, "/cdn/private/upload", response_body: {
        "uploadUrl" => "https://s3.amazonaws.com/...",
        "fileId" => "file_123",
        "expiresAt" => "2024-01-15T11:00:00Z"
      })

      result = cdn.get_private_upload_url(
        project_slug: "my-project",
        filename: "secret.pdf",
        mime_type: "application/pdf",
        size: 50000
      )

      expect(result["fileId"]).to eq("file_123")
      expect(result["expiresAt"]).to be_a(Time)
    end
  end

  describe "#get_private_download_url" do
    it "generates a private download URL" do
      stub_stack0_request(:post, "/cdn/private/file_123/download", response_body: {
        "downloadUrl" => "https://s3.amazonaws.com/...",
        "expiresAt" => "2024-01-15T11:00:00Z"
      })

      result = cdn.get_private_download_url(file_id: "file_123", expires_in: 3600)

      expect(result["expiresAt"]).to be_a(Time)
    end
  end

  describe "#list_private_files" do
    it "lists private files" do
      stub_stack0_request(:get, "/cdn/private?projectSlug=my-project", response_body: {
        "files" => [
          { "id" => "file_1", "filename" => "doc.pdf", "createdAt" => "2024-01-15T10:00:00Z" }
        ],
        "total" => 1
      })

      result = cdn.list_private_files(project_slug: "my-project")

      expect(result["files"].length).to eq(1)
      expect(result["files"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#create_bundle" do
    it "creates a download bundle" do
      stub_stack0_request(:post, "/cdn/bundles", response_body: {
        "bundle" => {
          "id" => "bundle_123",
          "name" => "Assets Bundle",
          "createdAt" => "2024-01-15T10:00:00Z"
        }
      })

      result = cdn.create_bundle(
        project_slug: "my-project",
        name: "Assets Bundle",
        asset_ids: %w[asset_1 asset_2]
      )

      expect(result["bundle"]["id"]).to eq("bundle_123")
      expect(result["bundle"]["createdAt"]).to be_a(Time)
    end
  end

  describe "#get_bundle_download_url" do
    it "retrieves a bundle download URL" do
      stub_stack0_request(:post, "/cdn/bundles/bundle_123/download", response_body: {
        "downloadUrl" => "https://s3.amazonaws.com/...",
        "expiresAt" => "2024-01-15T11:00:00Z"
      })

      result = cdn.get_bundle_download_url(bundle_id: "bundle_123")

      expect(result["expiresAt"]).to be_a(Time)
    end
  end

  describe "#get_usage" do
    it "retrieves usage statistics" do
      stub_stack0_request(:get, "/cdn/usage", response_body: {
        "storageUsed" => 1024000,
        "bandwidthUsed" => 5120000,
        "assetCount" => 150,
        "periodStart" => "2024-01-01T00:00:00Z",
        "periodEnd" => "2024-01-31T23:59:59Z"
      })

      result = cdn.get_usage

      expect(result["storageUsed"]).to eq(1024000)
      expect(result["assetCount"]).to eq(150)
      expect(result["periodStart"]).to be_a(Time)
    end
  end

  describe "#get_usage_history" do
    it "retrieves usage history" do
      stub_stack0_request(:get, "/cdn/usage/history?days=7", response_body: {
        "data" => [
          { "timestamp" => "2024-01-15T00:00:00Z", "bandwidth" => 100000, "storage" => 50000 }
        ]
      })

      result = cdn.get_usage_history(days: 7)

      expect(result["data"][0]["timestamp"]).to be_a(Time)
    end
  end

  describe "#create_import" do
    it "creates an S3 import job" do
      stub_stack0_request(:post, "/cdn/imports", response_body: {
        "id" => "import_123",
        "status" => "pending",
        "createdAt" => "2024-01-15T10:00:00Z"
      })

      result = cdn.create_import(
        project_slug: "my-project",
        source_bucket: "my-bucket",
        source_region: "us-east-1",
        auth_type: "role",
        role_arn: "arn:aws:iam::123456789:role/ImportRole"
      )

      expect(result["id"]).to eq("import_123")
      expect(result["createdAt"]).to be_a(Time)
    end
  end
end
