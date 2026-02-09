# Stack0 Ruby SDK

Official Ruby SDK for the [Stack0](https://stack0.dev) platform. Provides a complete interface for Mail, CDN, Screenshots, Extraction, Integrations, and Marketing APIs.

[![Gem Version](https://badge.fury.io/rb/stack0.svg)](https://rubygems.org/gems/stack0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Requirements

- Ruby >= 3.0.0

## Installation

Add to your Gemfile:

```ruby
gem "stack0"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install stack0
```

## Quick Start

```ruby
require "stack0"

client = Stack0::Client.new(api_key: "stack0_...")

# Send an email
client.mail.send(
  from: "hello@example.com",
  to: "user@example.com",
  subject: "Hello from Stack0",
  html: "<h1>Welcome!</h1>"
)

# Capture a screenshot and wait for it to complete
screenshot = client.screenshots.capture_and_wait(url: "https://example.com")
puts screenshot["imageUrl"]

# Extract content from a webpage
extraction = client.extraction.extract_and_wait(
  url: "https://example.com/article",
  mode: "markdown"
)
puts extraction["markdown"]
```

## Configuration

### Direct Initialization

```ruby
client = Stack0::Client.new(
  api_key: "stack0_...",
  base_url: "https://api.stack0.dev/v1", # default
  cdn_url: nil,                           # optional, for image transforms
  timeout: 30                             # seconds, default
)
```

### Global Configuration

```ruby
Stack0.configure do |config|
  config.api_key = ENV["STACK0_API_KEY"]
  config.base_url = "https://api.stack0.dev/v1"
  config.cdn_url = "https://cdn.stack0.io"
  config.timeout = 60
end

client = Stack0.client
```

## Client Modules

The client exposes the following top-level modules:

| Property               | Description                                      |
|------------------------|--------------------------------------------------|
| `client.mail`          | Transactional email, broadcasts, and management  |
| `client.cdn`           | Asset uploads, transforms, video, private files  |
| `client.screenshots`   | Webpage screenshot capture and scheduling        |
| `client.extraction`    | AI-powered content extraction from webpages      |
| `client.integrations`  | Third-party service connections and unified APIs  |
| `client.marketing`     | Trend discovery, content creation, and analytics |

---

## Mail

### Sending Emails

```ruby
# Simple email
result = client.mail.send(
  from: "hello@example.com",
  to: "user@example.com",
  subject: "Welcome!",
  html: "<h1>Welcome aboard</h1>"
)
puts result["id"]

# With named sender and multiple recipients
client.mail.send(
  from: { name: "Acme Inc", email: "noreply@acme.com" },
  to: ["alice@example.com", "bob@example.com"],
  cc: "manager@example.com",
  bcc: "audit@example.com",
  subject: "Team Update",
  html: "<p>Quarterly results</p>",
  text: "Quarterly results"
)

# With template
client.mail.send(
  from: "hello@example.com",
  to: "user@example.com",
  subject: "Welcome {{name}}",
  template_id: "tmpl_abc123",
  template_variables: { name: "Alice", url: "https://example.com/activate" }
)

# With attachments, tags, metadata, and scheduled delivery
client.mail.send(
  from: "billing@example.com",
  to: "user@example.com",
  subject: "Your Invoice",
  html: "<p>See attached.</p>",
  attachments: [
    { filename: "invoice.pdf", content: Base64.encode64(pdf_data), contentType: "application/pdf" }
  ],
  tags: ["billing", "invoice"],
  metadata: { order_id: "12345" },
  scheduled_at: Time.now + 3600
)
```

### Batch and Broadcast

```ruby
# Send up to 100 emails in a single batch
client.mail.send_batch(emails: [
  { from: "hi@example.com", to: "a@example.com", subject: "Hello A", html: "<p>Hi A</p>" },
  { from: "hi@example.com", to: "b@example.com", subject: "Hello B", html: "<p>Hi B</p>" }
])

# Broadcast the same content to up to 1000 recipients
client.mail.send_broadcast(
  from: "news@example.com",
  to: ["subscriber1@example.com", "subscriber2@example.com"],
  subject: "Weekly Digest",
  html: "<h1>This week in review</h1>"
)
```

### Retrieving and Managing Emails

```ruby
# Get a sent email
email = client.mail.get("email-id")
puts email["status"]       # "sent", "delivered", "bounced", etc.
puts email["deliveredAt"]  # Time object or nil

# List emails with filters
result = client.mail.list(status: "delivered", limit: 20, sort_by: "createdAt", sort_order: "desc")
result["emails"].each { |e| puts e["subject"] }

# Resend or cancel
client.mail.resend("email-id")
client.mail.cancel("scheduled-email-id")
```

### Analytics

```ruby
analytics = client.mail.get_analytics
time_series = client.mail.get_time_series_analytics(days: 30)
hourly = client.mail.get_hourly_analytics
senders = client.mail.list_senders(search: "noreply")
```

### Mail Sub-clients

#### Domains

```ruby
domains = client.mail.domains.list
client.mail.domains.add(domain: "mail.example.com")
records = client.mail.domains.get_dns_records("domain-id")
client.mail.domains.verify("domain-id")
client.mail.domains.set_default("domain-id")
client.mail.domains.delete("domain-id")
```

#### Templates

```ruby
client.mail.templates.create(
  name: "Welcome",
  slug: "welcome",
  subject: "Welcome {{name}}",
  html: "<h1>Hello {{name}}</h1>"
)

template = client.mail.templates.get("template-id")
template = client.mail.templates.get_by_slug("welcome")

preview = client.mail.templates.preview(
  id: "template-id",
  variables: { name: "Alice" }
)

client.mail.templates.update(id: "template-id", subject: "Updated Subject")
client.mail.templates.delete("template-id")
```

#### Audiences

```ruby
audience = client.mail.audiences.create(name: "Newsletter Subscribers")
client.mail.audiences.add_contacts(id: audience["id"], contact_ids: ["contact-1", "contact-2"])
client.mail.audiences.list_contacts(id: audience["id"])
client.mail.audiences.remove_contacts(id: audience["id"], contact_ids: ["contact-1"])
```

#### Contacts

```ruby
contact = client.mail.contacts.create(email: "user@example.com")
client.mail.contacts.update(id: contact["id"], first_name: "Alice")
client.mail.contacts.list(search: "alice")
client.mail.contacts.import(contacts: [
  { email: "a@example.com", first_name: "A" },
  { email: "b@example.com", first_name: "B" }
])
client.mail.contacts.delete(contact["id"])
```

#### Campaigns

```ruby
campaign = client.mail.campaigns.create(
  name: "Product Launch",
  subject: "Introducing our new product",
  from_email: "marketing@example.com"
)

client.mail.campaigns.send_campaign(id: campaign["id"], send_now: true)
# Or schedule: send_campaign(id: campaign["id"], scheduled_at: Time.now + 86400)

stats = client.mail.campaigns.get_stats(campaign["id"])
client.mail.campaigns.pause(campaign["id"])
client.mail.campaigns.cancel(campaign["id"])
client.mail.campaigns.duplicate(campaign["id"])
```

#### Sequences

The sequences sub-client provides a full visual builder API for automated email flows.

```ruby
# Create and manage sequences
sequence = client.mail.sequences.create(name: "Onboarding", trigger_type: "event")
client.mail.sequences.publish(sequence["id"])

# Node management
client.mail.sequences.create_node(sequence_id: sequence["id"], type: "email", position: { x: 0, y: 100 })
client.mail.sequences.set_node_email(node_id: "node-id", subject: "Welcome", html: "<p>Hi!</p>")
client.mail.sequences.set_node_timer(node_id: "node-id", delay_value: 2, delay_unit: "days")

# Connections between nodes
client.mail.sequences.create_connection(
  sequence_id: sequence["id"],
  source_node_id: "node-a",
  target_node_id: "node-b"
)

# Entry management
client.mail.sequences.add_contact(sequence_id: sequence["id"], contact_id: "contact-id")
entries = client.mail.sequences.list_entries(sequence_id: sequence["id"])

# Lifecycle
client.mail.sequences.pause(sequence["id"])
client.mail.sequences.resume(sequence["id"])
client.mail.sequences.archive(sequence["id"])
client.mail.sequences.duplicate(sequence["id"])
analytics = client.mail.sequences.get_analytics(sequence["id"])
```

#### Events

```ruby
client.mail.events.create(name: "user.signed_up")
client.mail.events.track(event_name: "user.signed_up", contact_id: "contact-id")
client.mail.events.track_batch(events: [
  { event_name: "page.viewed", contact_id: "contact-id", properties: { page: "/pricing" } }
])
occurrences = client.mail.events.list_occurrences
analytics = client.mail.events.get_analytics("event-id")
```

---

## CDN

### Asset Upload Flow

```ruby
# 1. Get a presigned upload URL
upload = client.cdn.get_upload_url(
  project_slug: "my-project",
  filename: "photo.jpg",
  mime_type: "image/jpeg",
  size: File.size("photo.jpg")
)

# 2. Upload the file to the presigned URL (using your HTTP library of choice)
require "net/http"
uri = URI(upload["uploadUrl"])
Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  req = Net::HTTP::Put.new(uri)
  req["Content-Type"] = "image/jpeg"
  req.body = File.binread("photo.jpg")
  http.request(req)
end

# 3. Confirm the upload
asset = client.cdn.confirm_upload(upload["assetId"])
puts asset["cdnUrl"]
```

### Asset Management

```ruby
# List assets
result = client.cdn.list(project_slug: "my-project", type: "image", limit: 20)
result["assets"].each { |a| puts "#{a["filename"]} - #{a["cdnUrl"]}" }

# Get, update, delete
asset = client.cdn.get("asset-id")
client.cdn.update(id: "asset-id", tags: ["hero", "landing"], alt: "Hero image")
client.cdn.delete("asset-id")
client.cdn.delete_many(["asset-1", "asset-2"])
client.cdn.move(asset_ids: ["asset-1"], folder: "/archive")
```

### Image Transformations

Generate optimized image URLs client-side with no API call:

```ruby
# Using a full CDN URL
url = client.cdn.get_transform_url("https://cdn.stack0.io/my-project/photo.jpg",
  width: 800,
  height: 600,
  fit: "cover",
  format: "webp",
  quality: 80
)

# Advanced transforms
url = client.cdn.get_transform_url(asset["cdnUrl"],
  width: 400,
  grayscale: true,
  blur: 5,
  rotate: 90
)
```

Available transform options: `format`, `quality`, `width`, `height`, `fit`, `crop`, `blur`, `sharpen`, `brightness`, `saturation`, `grayscale`, `rotate`, `flip`, `flop`.

### Folders

```ruby
tree = client.cdn.get_folder_tree(project_slug: "my-project", max_depth: 3)
folder = client.cdn.create_folder(project_slug: "my-project", name: "avatars", parent_id: "parent-id")
client.cdn.update_folder(id: folder["id"], name: "profile-avatars")
client.cdn.move_folder(id: folder["id"], new_parent_id: "other-folder-id")
client.cdn.delete_folder(folder["id"], delete_contents: true)
```

### Video Transcoding

```ruby
job = client.cdn.transcode(
  project_slug: "my-project",
  asset_id: "video-asset-id",
  output_format: "hls",
  variants: [
    { quality: "720p", codec: "h264" },
    { quality: "1080p", codec: "h264" }
  ],
  webhook_url: "https://example.com/webhook"
)

# Check job status
job = client.cdn.get_job(job["id"])
puts "Status: #{job["status"]}, Progress: #{job["progress"]}%"

# Get streaming URLs for playback
urls = client.cdn.get_streaming_urls("asset-id")
puts urls["hlsUrl"]

# Thumbnails
thumb = client.cdn.get_thumbnail(asset_id: "video-id", timestamp: 10.5, width: 320, format: "webp")
client.cdn.regenerate_thumbnail(asset_id: "video-id", timestamp: 5.0)
thumbnails = client.cdn.list_thumbnails("video-id")

# Audio extraction
client.cdn.extract_audio(project_slug: "my-project", asset_id: "video-id", format: "mp3", bitrate: 192)
```

### GIF Generation

```ruby
gif = client.cdn.generate_gif(
  project_slug: "my-project",
  asset_id: "video-id",
  start_time: 5.0,
  duration: 3.0,
  width: 480,
  fps: 15
)
gifs = client.cdn.list_gifs(asset_id: "video-id")
```

### Video Merge

```ruby
merge = client.cdn.create_merge_job(
  project_slug: "my-project",
  inputs: [
    { assetId: "clip-1", trim: { start: 0, end: 10 } },
    { assetId: "clip-2" }
  ]
)
client.cdn.get_merge_job(merge["id"])
client.cdn.cancel_merge_job(merge["id"])
```

### Private Files

```ruby
upload = client.cdn.get_private_upload_url(
  project_slug: "my-project",
  filename: "contract.pdf",
  mime_type: "application/pdf",
  size: 204800
)
# ... upload to presigned URL ...
file = client.cdn.confirm_private_upload(upload["fileId"])

# Generate a time-limited download URL
download = client.cdn.get_private_download_url(file_id: file["id"], expires_in: 3600)
puts download["downloadUrl"]

# Management
client.cdn.list_private_files(project_slug: "my-project")
client.cdn.update_private_file(file_id: file["id"], description: "Q4 Contract")
client.cdn.move_private_files(file_ids: [file["id"]], folder: "/contracts")
client.cdn.delete_private_file(file["id"])
```

### Download Bundles

```ruby
bundle = client.cdn.create_bundle(
  project_slug: "my-project",
  name: "Design Assets Q4",
  asset_ids: ["asset-1", "asset-2"],
  expires_in: 86400
)
url = client.cdn.get_bundle_download_url(bundle_id: bundle["bundle"]["id"])
client.cdn.delete_bundle(bundle["bundle"]["id"])
```

### S3 Import

```ruby
import = client.cdn.create_import(
  project_slug: "my-project",
  source_bucket: "my-s3-bucket",
  source_region: "us-east-1",
  auth_type: "access_key",
  access_key_id: "AKIA...",
  secret_access_key: "...",
  source_prefix: "images/"
)
client.cdn.get_import(import["id"])
client.cdn.list_import_files(import_id: import["id"])
client.cdn.retry_import(import["id"])
client.cdn.cancel_import(import["id"])
```

### CDN Usage

```ruby
usage = client.cdn.get_usage(project_slug: "my-project")
history = client.cdn.get_usage_history(project_slug: "my-project", days: 30)
breakdown = client.cdn.get_storage_breakdown(project_slug: "my-project", group_by: "type")
```

---

## Screenshots

### Capture

```ruby
# Fire-and-forget (returns immediately with job ID)
job = client.screenshots.capture(url: "https://example.com", format: "png", full_page: true)

# Capture and wait for completion (polls until done)
screenshot = client.screenshots.capture_and_wait(
  url: "https://example.com",
  format: "png",
  full_page: true,
  block_ads: true,
  block_cookie_banners: true,
  device_type: "desktop",
  viewport_width: 1280,
  viewport_height: 720,
  poll_interval: 1,
  timeout: 60
)
puts screenshot["imageUrl"]
```

### Retrieve and Manage

```ruby
screenshot = client.screenshots.get(id: "screenshot-id")
result = client.screenshots.list(status: "completed", limit: 10)
client.screenshots.delete(id: "screenshot-id")
```

### Batch Screenshots

```ruby
job = client.screenshots.batch_and_wait(
  urls: ["https://example.com", "https://example.org"],
  config: { format: "png", full_page: true, block_ads: true },
  poll_interval: 2,
  timeout: 300
)

# Or manage the batch manually
job = client.screenshots.batch(urls: ["https://example.com", "https://example.org"])
status = client.screenshots.get_batch_job(id: job["id"])
client.screenshots.cancel_batch_job(id: job["id"])
```

### Schedules

```ruby
schedule = client.screenshots.create_schedule(
  name: "Daily Homepage Check",
  url: "https://example.com",
  frequency: "daily",
  config: { format: "png", full_page: true },
  detect_changes: true,
  change_threshold: 0.05
)

client.screenshots.update_schedule(id: schedule["id"], frequency: "hourly")
client.screenshots.toggle_schedule(id: schedule["id"])
client.screenshots.list_schedules(is_active: true)
client.screenshots.delete_schedule(id: schedule["id"])
```

---

## Extraction

### Extract Content

```ruby
# Markdown extraction with polling
extraction = client.extraction.extract_and_wait(
  url: "https://example.com/blog/post",
  mode: "markdown",
  include_metadata: true,
  include_links: true,
  poll_interval: 1,
  timeout: 60
)
puts extraction["markdown"]
puts extraction["pageMetadata"]

# Schema-based structured extraction
extraction = client.extraction.extract_and_wait(
  url: "https://example.com/product",
  mode: "schema",
  schema: {
    type: "object",
    properties: {
      name: { type: "string" },
      price: { type: "number" },
      description: { type: "string" }
    },
    required: ["name", "price"]
  }
)
puts extraction["extractedData"]
```

### Extraction Modes

| Mode       | Description                               |
|------------|-------------------------------------------|
| `auto`     | AI determines the best extraction format  |
| `schema`   | Structured data matching a JSON schema    |
| `markdown` | AI-cleaned markdown content               |
| `raw`      | Raw HTML content                          |

### Retrieve and Manage

```ruby
extraction = client.extraction.get(id: "extraction-id")
result = client.extraction.list(status: "completed", limit: 20)
client.extraction.delete(id: "extraction-id")
```

### Batch Extractions

```ruby
job = client.extraction.batch_and_wait(
  urls: ["https://example.com/page1", "https://example.com/page2"],
  config: { mode: "markdown" },
  poll_interval: 2,
  timeout: 300
)
```

### Schedules

```ruby
schedule = client.extraction.create_schedule(
  name: "Daily Price Monitor",
  url: "https://example.com/pricing",
  config: { mode: "schema", schema: { type: "object", properties: { price: { type: "number" } } } },
  frequency: "daily",
  detect_changes: true
)

client.extraction.toggle_schedule(id: schedule["id"])
```

### Usage

```ruby
usage = client.extraction.get_usage
daily = client.extraction.get_usage_daily
```

---

## Integrations

### Connections

```ruby
# Browse available connectors
connectors = client.integrations.list_connectors(category: "crm")
connector = client.integrations.get_connector("salesforce")

# Initiate OAuth flow
oauth = client.integrations.initiate_oauth(
  connector_slug: "salesforce",
  redirect_url: "https://myapp.com/callback"
)
puts oauth["authUrl"] # Redirect user here

# Complete OAuth (in your callback handler)
result = client.integrations.complete_oauth(
  code: params[:code],
  state: params[:state],
  redirect_url: "https://myapp.com/callback"
)

# Manage connections
connections = client.integrations.list_connections(status: "active")
client.integrations.update_connection(connection_id: "conn-id", name: "Production Salesforce")
client.integrations.reconnect_connection(connection_id: "conn-id", redirect_url: "https://myapp.com/callback")
client.integrations.delete_connection("conn-id")
```

### Passthrough Requests

Make raw API calls to the underlying provider:

```ruby
response = client.integrations.passthrough(
  connection_id: "conn-id",
  method: "GET",
  path: "/api/v1/contacts",
  headers: { "X-Custom" => "value" }
)
```

### Unified CRM

```ruby
# Contacts
contacts = client.integrations.crm.list_contacts(connection_id: "conn-id")
contact = client.integrations.crm.get_contact(connection_id: "conn-id", contact_id: "ext-id")
client.integrations.crm.create_contact(connection_id: "conn-id", data: { email: "new@example.com" })
client.integrations.crm.update_contact(connection_id: "conn-id", contact_id: "ext-id", data: { phone: "555-1234" })
client.integrations.crm.delete_contact(connection_id: "conn-id", contact_id: "ext-id")

# Companies and Deals follow the same pattern
companies = client.integrations.crm.list_companies(connection_id: "conn-id")
deals = client.integrations.crm.list_deals(connection_id: "conn-id")
```

### Unified Storage

```ruby
files = client.integrations.storage.list_files(connection_id: "conn-id")
client.integrations.storage.upload_file(connection_id: "conn-id", data: { name: "doc.pdf", content: "..." })
url = client.integrations.storage.download_file(connection_id: "conn-id", file_id: "file-id")

folders = client.integrations.storage.list_folders(connection_id: "conn-id")
client.integrations.storage.create_folder(connection_id: "conn-id", data: { name: "Reports" })
```

### Unified Communication

```ruby
channels = client.integrations.communication.list_channels(connection_id: "conn-id")
messages = client.integrations.communication.list_messages(connection_id: "conn-id", channel_id: "ch-id")
client.integrations.communication.send_message(connection_id: "conn-id", channel_id: "ch-id", data: { text: "Hello!" })
users = client.integrations.communication.list_users(connection_id: "conn-id")
```

### Unified Productivity

```ruby
docs = client.integrations.productivity.list_documents(connection_id: "conn-id")
client.integrations.productivity.create_document(connection_id: "conn-id", data: { title: "Meeting Notes" })

tables = client.integrations.productivity.list_tables(connection_id: "conn-id")
rows = client.integrations.productivity.list_table_rows(connection_id: "conn-id", table_id: "tbl-id")
client.integrations.productivity.create_table_row(connection_id: "conn-id", table_id: "tbl-id", data: { name: "Row 1" })
```

### Stats and Logs

```ruby
stats = client.integrations.get_stats
logs = client.integrations.list_logs(connection_id: "conn-id", limit: 50)
```

---

## Marketing

### Trends

```ruby
client.marketing.discover_trends(project_slug: "my-project", environment: "production")
trends = client.marketing.list_trends(project_slug: "my-project", environment: "production", status: "active")
trend = client.marketing.get_trend("trend-id")
client.marketing.update_trend_status(trend_id: "trend-id", status: "dismissed")
```

### Opportunities

```ruby
client.marketing.generate_opportunities(project_slug: "my-project", environment: "production")
opps = client.marketing.list_opportunities(project_slug: "my-project", environment: "production")
opp = client.marketing.get_opportunity("opp-id")
client.marketing.dismiss_opportunity("opp-id")
```

### Content

```ruby
content = client.marketing.create_content(
  project_slug: "my-project",
  environment: "production",
  content_type: "tiktok_slideshow",
  title: "5 Tips for Developers",
  opportunity_id: "opp-id"
)

all_content = client.marketing.list_content(
  project_slug: "my-project",
  environment: "production",
  status: "draft"
)

client.marketing.update_content(content_id: content["id"], title: "Updated Title")
client.marketing.approve_content(content_id: content["id"], review_notes: "Looks great")
client.marketing.reject_content(content_id: content["id"], review_notes: "Needs revision")
client.marketing.delete_content(content["id"])
```

### Scripts

```ruby
script = client.marketing.create_script(
  project_slug: "my-project",
  environment: "production",
  hook: "Did you know...",
  slides: [{ text: "Slide 1 content" }, { text: "Slide 2 content" }],
  cta: "Follow for more!",
  content_id: content["id"]
)

client.marketing.update_script(script_id: script["id"], hook: "Updated hook")
client.marketing.create_script_version(script_id: script["id"], hook: "V2", slides: [{ text: "New slide" }], cta: "Subscribe!")
versions = client.marketing.get_script_versions(script["id"])
client.marketing.delete_script(script["id"])
```

### Calendar

```ruby
entry = client.marketing.schedule_content(
  project_slug: "my-project",
  content_id: content["id"],
  scheduled_for: Time.now + 86400,
  auto_publish: true
)

entries = client.marketing.list_calendar_entries(project_slug: "my-project", start_date: Time.now, end_date: Time.now + 604800)
client.marketing.update_calendar_entry(entry_id: entry["id"], scheduled_for: Time.now + 172800)
client.marketing.cancel_calendar_entry(entry["id"])
client.marketing.mark_content_published(entry_id: entry["id"])
```

### Asset Jobs

```ruby
job = client.marketing.create_asset_job(
  project_slug: "my-project",
  content_id: content["id"],
  job_type: "slide_generation"
)

jobs = client.marketing.list_asset_jobs(project_slug: "my-project", status: "pending")
client.marketing.retry_asset_job(job["id"])
client.marketing.cancel_asset_job(job["id"])
```

### Analytics

```ruby
overview = client.marketing.get_analytics_overview(project_slug: "my-project", environment: "production")
perf = client.marketing.get_content_performance(project_slug: "my-project", environment: "production")
trend_data = client.marketing.get_trend_analytics(project_slug: "my-project")
conversion = client.marketing.get_opportunity_conversion(project_slug: "my-project")
```

### Settings and Usage

```ruby
settings = client.marketing.get_settings(project_slug: "my-project")
client.marketing.update_settings(
  project_slug: "my-project",
  brand_voice: "Professional and approachable",
  monitored_keywords: ["ruby", "developer tools", "saas"]
)

current = client.marketing.get_current_usage(project_slug: "my-project")
history = client.marketing.get_usage_history(project_slug: "my-project")
total = client.marketing.get_total_usage(project_slug: "my-project")
client.marketing.record_usage(project_slug: "my-project", usage_type: "content_generated", amount: 1)
```

---

## Error Handling

All API errors inherit from `Stack0::Error`. HTTP errors are mapped to specific exception classes:

| Class                          | HTTP Status | Description              |
|--------------------------------|-------------|--------------------------|
| `Stack0::AuthenticationError`  | 401         | Invalid or missing API key |
| `Stack0::NotFoundError`        | 404         | Resource not found       |
| `Stack0::ValidationError`      | 422         | Invalid request data     |
| `Stack0::RateLimitError`       | 429         | Too many requests        |
| `Stack0::APIError`             | Other       | Generic API error        |
| `Stack0::TimeoutError`         | N/A         | Polling operation timeout |

```ruby
begin
  client.mail.send(
    from: "hello@example.com",
    to: "user@example.com",
    subject: "Test",
    html: "<p>Hello</p>"
  )
rescue Stack0::AuthenticationError => e
  puts "Check your API key: #{e.message}"
rescue Stack0::ValidationError => e
  puts "Invalid request: #{e.message}"
  puts "Details: #{e.response}"
rescue Stack0::RateLimitError => e
  puts "Rate limited (status #{e.status_code}), retry later"
rescue Stack0::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue Stack0::APIError => e
  puts "API error #{e.status_code}: #{e.message}"
  puts "Error code: #{e.code}"
  puts "Response body: #{e.response}"
rescue Stack0::TimeoutError => e
  puts "Operation timed out: #{e.message}"
end
```

---

## Polling Utility

For async operations (screenshots, extractions), the SDK provides convenience `*_and_wait` methods that poll until completion. You can also use the polling module directly:

```ruby
Stack0::Polling.poll_until_complete(
  initial_id: "job-id",
  get_method: ->(id) { client.screenshots.get(id: id) },
  completed_statuses: ["completed"],
  failed_statuses: ["failed"],
  poll_interval: 1,  # seconds between polls
  timeout: 60        # maximum wait time in seconds
)
```

---

## Documentation

For full API reference and guides, visit [https://stack0.dev/docs](https://stack0.dev/docs).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/stack0dev/sdk-ruby](https://github.com/stack0dev/sdk-ruby).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
