# frozen_string_literal: true

RSpec.describe Stack0::Mail::Templates do
  let(:client) { test_client }
  let(:templates) { client.mail.templates }

  describe "#list" do
    it "lists templates" do
      stub_stack0_request(:get, "/mail/templates", response_body: {
        "templates" => [
          { "id" => "tmpl_1", "name" => "Welcome", "slug" => "welcome", "isActive" => true },
          { "id" => "tmpl_2", "name" => "Reset Password", "slug" => "reset-password", "isActive" => true }
        ],
        "total" => 2
      })

      result = templates.list

      expect(result["templates"].length).to eq(2)
      expect(result["templates"][0]["name"]).to eq("Welcome")
    end

    it "filters by environment and active status" do
      stub_stack0_request(:get, "/mail/templates?environment=production&isActive=true", response_body: {
        "templates" => [
          { "id" => "tmpl_1", "name" => "Welcome", "isActive" => true }
        ],
        "total" => 1
      })

      result = templates.list(environment: "production", is_active: true)

      expect(result["templates"].length).to eq(1)
    end

    it "supports pagination and search" do
      stub_stack0_request(:get, "/mail/templates?limit=10&offset=20&search=welcome", response_body: {
        "templates" => [],
        "total" => 0
      })

      result = templates.list(limit: 10, offset: 20, search: "welcome")

      expect(result["templates"]).to eq([])
    end
  end

  describe "#get" do
    it "retrieves a template by ID" do
      stub_stack0_request(:get, "/mail/templates/tmpl_123", response_body: {
        "id" => "tmpl_123",
        "name" => "Welcome Email",
        "slug" => "welcome",
        "subject" => "Welcome to {{company}}",
        "html" => "<h1>Welcome, {{name}}!</h1>",
        "text" => "Welcome, {{name}}!",
        "isActive" => true
      })

      result = templates.get("tmpl_123")

      expect(result["id"]).to eq("tmpl_123")
      expect(result["subject"]).to eq("Welcome to {{company}}")
    end
  end

  describe "#get_by_slug" do
    it "retrieves a template by slug" do
      stub_stack0_request(:get, "/mail/templates/slug/welcome", response_body: {
        "id" => "tmpl_123",
        "name" => "Welcome Email",
        "slug" => "welcome"
      })

      result = templates.get_by_slug("welcome")

      expect(result["slug"]).to eq("welcome")
    end
  end

  describe "#create" do
    it "creates a new template" do
      stub_stack0_request(:post, "/mail/templates", response_body: {
        "id" => "tmpl_new",
        "name" => "New Template",
        "slug" => "new-template",
        "subject" => "Hello",
        "html" => "<p>Content</p>",
        "isActive" => true
      })

      result = templates.create(
        name: "New Template",
        slug: "new-template",
        subject: "Hello",
        html: "<p>Content</p>"
      )

      expect(result["id"]).to eq("tmpl_new")
      expect(result["name"]).to eq("New Template")
    end

    it "creates a template with all options" do
      stub_stack0_request(:post, "/mail/templates", response_body: {
        "id" => "tmpl_full",
        "name" => "Full Template",
        "slug" => "full-template",
        "description" => "A complete template",
        "subject" => "Subject",
        "previewText" => "Preview here",
        "html" => "<p>HTML</p>",
        "text" => "Plain text",
        "variablesSchema" => { "name" => { "type" => "string" } },
        "isActive" => false
      })

      result = templates.create(
        name: "Full Template",
        slug: "full-template",
        subject: "Subject",
        html: "<p>HTML</p>",
        description: "A complete template",
        preview_text: "Preview here",
        text: "Plain text",
        variables_schema: { "name" => { "type" => "string" } },
        is_active: false
      )

      expect(result["id"]).to eq("tmpl_full")
      expect(result["previewText"]).to eq("Preview here")
    end
  end

  describe "#update" do
    it "updates a template" do
      stub_stack0_request(:put, "/mail/templates/tmpl_123", response_body: {
        "id" => "tmpl_123",
        "name" => "Updated Template",
        "subject" => "Updated Subject"
      })

      result = templates.update(
        id: "tmpl_123",
        name: "Updated Template",
        subject: "Updated Subject"
      )

      expect(result["name"]).to eq("Updated Template")
    end

    it "updates only specified fields" do
      stub_stack0_request(:put, "/mail/templates/tmpl_123", response_body: {
        "id" => "tmpl_123",
        "isActive" => false
      })

      result = templates.update(id: "tmpl_123", is_active: false)

      expect(result["isActive"]).to be(false)
    end
  end

  describe "#delete" do
    it "deletes a template" do
      stub_stack0_request(:delete, "/mail/templates/tmpl_123", response_body: {
        "success" => true
      })

      result = templates.delete("tmpl_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#preview" do
    it "previews a template with variables" do
      stub_stack0_request(:post, "/mail/templates/tmpl_123/preview", response_body: {
        "subject" => "Welcome to Acme",
        "html" => "<h1>Welcome, John!</h1>",
        "text" => "Welcome, John!"
      })

      result = templates.preview(
        id: "tmpl_123",
        variables: { "company" => "Acme", "name" => "John" }
      )

      expect(result["subject"]).to eq("Welcome to Acme")
      expect(result["html"]).to include("John")
    end
  end
end
