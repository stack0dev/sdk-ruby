# frozen_string_literal: true

RSpec.describe Stack0::Integrations::Client do
  let(:client) { test_client }
  let(:integrations) { client.integrations }

  describe "#list_connectors" do
    it "lists available connectors" do
      stub_stack0_request(:get, "/integrations/connectors", response_body: [
        { "slug" => "hubspot", "name" => "HubSpot", "category" => "crm" },
        { "slug" => "salesforce", "name" => "Salesforce", "category" => "crm" }
      ])

      result = integrations.list_connectors

      expect(result.length).to eq(2)
      expect(result[0]["slug"]).to eq("hubspot")
    end

    it "filters by category" do
      stub_stack0_request(:get, "/integrations/connectors?category=storage", response_body: [
        { "slug" => "google-drive", "name" => "Google Drive", "category" => "storage" }
      ])

      result = integrations.list_connectors(category: "storage")

      expect(result.length).to eq(1)
      expect(result[0]["category"]).to eq("storage")
    end
  end

  describe "#get_connector" do
    it "retrieves a connector by slug" do
      stub_stack0_request(:get, "/integrations/connectors/hubspot", response_body: {
        "slug" => "hubspot",
        "name" => "HubSpot",
        "category" => "crm",
        "authType" => "oauth2",
        "capabilities" => %w[contacts companies deals]
      })

      result = integrations.get_connector("hubspot")

      expect(result["slug"]).to eq("hubspot")
      expect(result["capabilities"]).to include("contacts")
    end
  end

  describe "#list_connections" do
    it "lists connections" do
      stub_stack0_request(:get, "/integrations/connections", response_body: {
        "connections" => [
          { "id" => "conn_1", "connectorSlug" => "hubspot", "status" => "connected", "createdAt" => "2024-01-15T10:00:00Z" }
        ]
      })

      result = integrations.list_connections

      expect(result["connections"].length).to eq(1)
      expect(result["connections"][0]["createdAt"]).to be_a(Time)
    end

    it "filters connections" do
      stub_stack0_request(:get, "/integrations/connections?status=connected&connectorSlug=hubspot", response_body: {
        "connections" => []
      })

      result = integrations.list_connections(status: "connected", connector_slug: "hubspot")

      expect(result["connections"]).to eq([])
    end
  end

  describe "#get_connection" do
    it "retrieves a connection by ID" do
      stub_stack0_request(:get, "/integrations/connections/conn_123", response_body: {
        "id" => "conn_123",
        "connectorSlug" => "hubspot",
        "name" => "My HubSpot",
        "status" => "connected",
        "externalAccountName" => "Acme Inc",
        "connectedAt" => "2024-01-15T10:00:00Z",
        "lastUsedAt" => "2024-01-16T12:00:00Z"
      })

      result = integrations.get_connection("conn_123")

      expect(result["id"]).to eq("conn_123")
      expect(result["connectedAt"]).to be_a(Time)
    end
  end

  describe "#initiate_oauth" do
    it "initiates OAuth flow" do
      stub_stack0_request(:post, "/integrations/connections/oauth/initiate", response_body: {
        "authUrl" => "https://accounts.hubspot.com/oauth/authorize?...",
        "connectionId" => "conn_123",
        "state" => "abc123"
      })

      result = integrations.initiate_oauth(
        connector_slug: "hubspot",
        redirect_url: "https://myapp.com/callback"
      )

      expect(result["authUrl"]).to include("hubspot.com")
      expect(result["connectionId"]).to eq("conn_123")
    end

    it "initiates OAuth with options" do
      stub_stack0_request(:post, "/integrations/connections/oauth/initiate", response_body: {
        "authUrl" => "https://auth.example.com/...",
        "connectionId" => "conn_456",
        "state" => "xyz789"
      })

      result = integrations.initiate_oauth(
        connector_slug: "salesforce",
        redirect_url: "https://myapp.com/callback",
        name: "My Salesforce",
        project_id: "proj_123",
        environment: "production"
      )

      expect(result["connectionId"]).to eq("conn_456")
    end
  end

  describe "#complete_oauth" do
    it "completes OAuth flow" do
      stub_stack0_request(:post, "/integrations/connections/oauth/callback", response_body: {
        "connectionId" => "conn_123",
        "externalAccountName" => "My HubSpot Account"
      })

      result = integrations.complete_oauth(
        code: "auth_code",
        state: "abc123",
        redirect_url: "https://myapp.com/callback"
      )

      expect(result["connectionId"]).to eq("conn_123")
    end
  end

  describe "#update_connection" do
    it "updates a connection" do
      stub_stack0_request(:patch, "/integrations/connections/conn_123", response_body: {
        "id" => "conn_123",
        "name" => "Updated Name",
        "isActive" => true
      })

      result = integrations.update_connection(connection_id: "conn_123", name: "Updated Name")

      expect(result["name"]).to eq("Updated Name")
    end
  end

  describe "#delete_connection" do
    it "deletes a connection" do
      stub_stack0_request(:delete, "/integrations/connections/conn_123", response_body: {
        "success" => true
      })

      result = integrations.delete_connection("conn_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#reconnect_connection" do
    it "reconnects an expired connection" do
      stub_stack0_request(:post, "/integrations/connections/conn_123/reconnect", response_body: {
        "authUrl" => "https://auth.example.com/...",
        "state" => "new_state"
      })

      result = integrations.reconnect_connection(
        connection_id: "conn_123",
        redirect_url: "https://myapp.com/callback"
      )

      expect(result["authUrl"]).to be_a(String)
    end
  end

  describe "#get_stats" do
    it "retrieves integration statistics" do
      stub_stack0_request(:get, "/integrations/connections/stats", response_body: {
        "totalConnections" => 10,
        "activeConnections" => 8,
        "failedConnections" => 2
      })

      result = integrations.get_stats

      expect(result["totalConnections"]).to eq(10)
    end
  end

  describe "#list_logs" do
    it "lists API logs" do
      stub_stack0_request(:get, "/integrations/logs", response_body: {
        "logs" => [
          {
            "id" => "log_1",
            "connectionId" => "conn_123",
            "method" => "GET",
            "path" => "/contacts",
            "statusCode" => 200,
            "createdAt" => "2024-01-15T10:00:00Z"
          }
        ]
      })

      result = integrations.list_logs

      expect(result["logs"].length).to eq(1)
      expect(result["logs"][0]["createdAt"]).to be_a(Time)
    end
  end

  describe "#passthrough" do
    it "makes a passthrough request" do
      stub_stack0_request(:post, "/integrations/passthrough", response_body: {
        "statusCode" => 200,
        "body" => { "contacts" => [] }
      })

      result = integrations.passthrough(
        connection_id: "conn_123",
        method: "GET",
        path: "/crm/v3/objects/contacts"
      )

      expect(result["statusCode"]).to eq(200)
    end
  end

  describe "CRM sub-client" do
    let(:crm) { integrations.crm }

    describe "#list_contacts" do
      it "lists contacts" do
        stub_stack0_request(:get, "/integrations/crm/contacts?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "contact_1", "firstName" => "John", "lastName" => "Doe" }
          ],
          "cursor" => nil
        })

        result = crm.list_contacts(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
        expect(result["items"][0]["firstName"]).to eq("John")
      end

      it "supports pagination and sorting" do
        stub_stack0_request(:get, "/integrations/crm/contacts?connectionId=conn_123&limit=10&sortBy=createdAt&sortOrder=desc",
                            response_body: {
                              "items" => [],
                              "cursor" => nil
                            })

        result = crm.list_contacts(connection_id: "conn_123", limit: 10, sort_by: "createdAt", sort_order: "desc")

        expect(result["items"]).to eq([])
      end
    end

    describe "#get_contact" do
      it "retrieves a contact by ID" do
        stub_stack0_request(:get, "/integrations/crm/contacts/contact_123?connectionId=conn_456", response_body: {
          "id" => "contact_123",
          "email" => "john@example.com",
          "firstName" => "John"
        })

        result = crm.get_contact(connection_id: "conn_456", id: "contact_123")

        expect(result["email"]).to eq("john@example.com")
      end
    end

    describe "#create_contact" do
      it "creates a contact" do
        stub_stack0_request(:post, "/integrations/crm/contacts", response_body: {
          "id" => "contact_new",
          "firstName" => "Jane",
          "lastName" => "Smith"
        })

        result = crm.create_contact(
          connection_id: "conn_123",
          data: { firstName: "Jane", lastName: "Smith", email: "jane@example.com" }
        )

        expect(result["id"]).to eq("contact_new")
      end
    end

    describe "#update_contact" do
      it "updates a contact" do
        stub_stack0_request(:patch, "/integrations/crm/contacts/contact_123", response_body: {
          "id" => "contact_123",
          "firstName" => "Updated"
        })

        result = crm.update_contact(
          connection_id: "conn_456",
          id: "contact_123",
          data: { firstName: "Updated" }
        )

        expect(result["firstName"]).to eq("Updated")
      end
    end

    describe "#delete_contact" do
      it "deletes a contact" do
        stub_stack0_request(:delete, "/integrations/crm/contacts/contact_123?connectionId=conn_456", response_body: {
          "success" => true
        })

        result = crm.delete_contact(connection_id: "conn_456", id: "contact_123")

        expect(result["success"]).to be(true)
      end
    end

    describe "#list_companies" do
      it "lists companies" do
        stub_stack0_request(:get, "/integrations/crm/companies?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "company_1", "name" => "Acme Inc" }
          ],
          "cursor" => nil
        })

        result = crm.list_companies(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
      end
    end

    describe "#list_deals" do
      it "lists deals" do
        stub_stack0_request(:get, "/integrations/crm/deals?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "deal_1", "name" => "Big Deal", "amount" => 50000 }
          ],
          "cursor" => nil
        })

        result = crm.list_deals(connection_id: "conn_123")

        expect(result["items"][0]["amount"]).to eq(50000)
      end
    end
  end

  describe "Storage sub-client" do
    let(:storage) { integrations.storage }

    describe "#list_files" do
      it "lists files" do
        stub_stack0_request(:get, "/integrations/storage/files?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "file_1", "name" => "document.pdf" }
          ],
          "cursor" => nil
        })

        result = storage.list_files(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
        expect(result["items"][0]["name"]).to eq("document.pdf")
      end
    end

    describe "#upload_file" do
      it "uploads a file" do
        stub_stack0_request(:post, "/integrations/storage/files", response_body: {
          "id" => "file_new",
          "name" => "test.txt",
          "mimeType" => "text/plain"
        })

        result = storage.upload_file(
          connection_id: "conn_123",
          name: "test.txt",
          mime_type: "text/plain",
          data: "Hello, World!"
        )

        expect(result["id"]).to eq("file_new")
      end
    end

    describe "#download_file" do
      it "downloads a file" do
        stub_stack0_request(:get, "/integrations/storage/files/file_123/download?connectionId=conn_456", response_body: {
          "data" => Base64.strict_encode64("File content"),
          "mimeType" => "text/plain",
          "filename" => "test.txt"
        })

        result = storage.download_file(connection_id: "conn_456", id: "file_123")

        expect(result[:data]).to eq("File content")
        expect(result[:mime_type]).to eq("text/plain")
      end
    end

    describe "#list_folders" do
      it "lists folders" do
        stub_stack0_request(:get, "/integrations/storage/folders?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "folder_1", "name" => "Documents" }
          ],
          "cursor" => nil
        })

        result = storage.list_folders(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
      end
    end

    describe "#create_folder" do
      it "creates a folder" do
        stub_stack0_request(:post, "/integrations/storage/folders", response_body: {
          "id" => "folder_new",
          "name" => "New Folder"
        })

        result = storage.create_folder(connection_id: "conn_123", name: "New Folder")

        expect(result["name"]).to eq("New Folder")
      end
    end
  end

  describe "Communication sub-client" do
    let(:communication) { integrations.communication }

    describe "#list_channels" do
      it "lists channels" do
        stub_stack0_request(:get, "/integrations/communication/channels?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "channel_1", "name" => "#general" }
          ],
          "cursor" => nil
        })

        result = communication.list_channels(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
      end
    end

    describe "#send_message" do
      it "sends a message" do
        stub_stack0_request(:post, "/integrations/communication/messages", response_body: {
          "id" => "msg_new",
          "content" => "Hello!"
        })

        result = communication.send_message(
          connection_id: "conn_123",
          channel_id: "channel_456",
          content: "Hello!"
        )

        expect(result["content"]).to eq("Hello!")
      end
    end

    describe "#list_users" do
      it "lists users" do
        stub_stack0_request(:get, "/integrations/communication/users?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "user_1", "name" => "John Doe" }
          ],
          "cursor" => nil
        })

        result = communication.list_users(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
      end
    end
  end

  describe "Productivity sub-client" do
    let(:productivity) { integrations.productivity }

    describe "#list_documents" do
      it "lists documents" do
        stub_stack0_request(:get, "/integrations/productivity/documents?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "doc_1", "title" => "Meeting Notes" }
          ],
          "cursor" => nil
        })

        result = productivity.list_documents(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
      end
    end

    describe "#create_document" do
      it "creates a document" do
        stub_stack0_request(:post, "/integrations/productivity/documents", response_body: {
          "id" => "doc_new",
          "title" => "New Document"
        })

        result = productivity.create_document(
          connection_id: "conn_123",
          title: "New Document",
          content: "Document content"
        )

        expect(result["title"]).to eq("New Document")
      end
    end

    describe "#list_tables" do
      it "lists tables" do
        stub_stack0_request(:get, "/integrations/productivity/tables?connectionId=conn_123", response_body: {
          "items" => [
            { "id" => "table_1", "name" => "Tasks" }
          ],
          "cursor" => nil
        })

        result = productivity.list_tables(connection_id: "conn_123")

        expect(result["items"].length).to eq(1)
      end
    end

    describe "#list_table_rows" do
      it "lists table rows" do
        stub_stack0_request(:get, "/integrations/productivity/tables/table_123/rows?connectionId=conn_456",
                            response_body: {
                              "items" => [
                                { "id" => "row_1", "fields" => { "name" => "Task 1" } }
                              ],
                              "cursor" => nil
                            })

        result = productivity.list_table_rows(connection_id: "conn_456", table_id: "table_123")

        expect(result["items"].length).to eq(1)
      end
    end

    describe "#create_table_row" do
      it "creates a table row" do
        stub_stack0_request(:post, "/integrations/productivity/tables/table_123/rows", response_body: {
          "id" => "row_new",
          "fields" => { "name" => "New Task" }
        })

        result = productivity.create_table_row(
          connection_id: "conn_123",
          table_id: "table_123",
          fields: { "name" => "New Task" }
        )

        expect(result["fields"]["name"]).to eq("New Task")
      end
    end
  end
end
