# frozen_string_literal: true

RSpec.describe Stack0::Mail::Client do
  let(:client) { test_client }
  let(:mail) { client.mail }

  describe "sub-clients" do
    it "provides access to domains client" do
      expect(mail.domains).to be_a(Stack0::Mail::Domains)
    end

    it "provides access to templates client" do
      expect(mail.templates).to be_a(Stack0::Mail::Templates)
    end

    it "provides access to audiences client" do
      expect(mail.audiences).to be_a(Stack0::Mail::Audiences)
    end

    it "provides access to contacts client" do
      expect(mail.contacts).to be_a(Stack0::Mail::Contacts)
    end

    it "provides access to campaigns client" do
      expect(mail.campaigns).to be_a(Stack0::Mail::Campaigns)
    end

    it "provides access to sequences client" do
      expect(mail.sequences).to be_a(Stack0::Mail::Sequences)
    end

    it "provides access to events client" do
      expect(mail.events).to be_a(Stack0::Mail::Events)
    end
  end

  describe "#send" do
    it "sends an email" do
      stub_stack0_request(:post, "/mail/send", response_body: {
        "id" => "email_123",
        "status" => "queued"
      })

      result = mail.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Email",
        html: "<p>Hello World</p>"
      )

      expect(result["id"]).to eq("email_123")
      expect(result["status"]).to eq("queued")
    end

    it "sends an email with all options" do
      stub_stack0_request(:post, "/mail/send", response_body: {
        "id" => "email_456",
        "status" => "queued"
      })

      result = mail.send(
        from: { email: "sender@example.com", name: "Sender Name" },
        to: ["recipient1@example.com", "recipient2@example.com"],
        subject: "Test Email",
        html: "<p>Hello World</p>",
        text: "Hello World",
        cc: "cc@example.com",
        bcc: "bcc@example.com",
        reply_to: "reply@example.com",
        tags: ["test", "example"],
        metadata: { "custom" => "value" }
      )

      expect(result["id"]).to eq("email_456")
    end

    it "sends an email with template" do
      stub_stack0_request(:post, "/mail/send", response_body: {
        "id" => "email_789",
        "status" => "queued"
      })

      result = mail.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Welcome!",
        template_id: "tmpl_123",
        template_variables: { "name" => "John" }
      )

      expect(result["id"]).to eq("email_789")
    end

    it "sends a scheduled email" do
      stub_stack0_request(:post, "/mail/send", response_body: {
        "id" => "email_scheduled",
        "status" => "scheduled"
      })

      result = mail.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Scheduled Email",
        html: "<p>Content</p>",
        scheduled_at: Time.parse("2024-02-01T10:00:00Z")
      )

      expect(result["status"]).to eq("scheduled")
    end

    it "sends an email with attachments" do
      stub_stack0_request(:post, "/mail/send", response_body: {
        "id" => "email_with_attach",
        "status" => "queued"
      })

      result = mail.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Email with attachment",
        html: "<p>See attachment</p>",
        attachments: [
          { "filename" => "doc.pdf", "content" => "base64content", "contentType" => "application/pdf" }
        ]
      )

      expect(result["id"]).to eq("email_with_attach")
    end
  end

  describe "#send_batch" do
    it "sends multiple emails in a batch" do
      stub_stack0_request(:post, "/mail/send/batch", response_body: {
        "sent" => 2,
        "failed" => 0,
        "results" => [
          { "id" => "email_1", "status" => "queued" },
          { "id" => "email_2", "status" => "queued" }
        ]
      })

      result = mail.send_batch(emails: [
        { from: "sender@example.com", to: "user1@example.com", subject: "Email 1", html: "<p>1</p>" },
        { from: "sender@example.com", to: "user2@example.com", subject: "Email 2", html: "<p>2</p>" }
      ])

      expect(result["sent"]).to eq(2)
      expect(result["results"].length).to eq(2)
    end

    it "sends batch with project slug" do
      stub_stack0_request(:post, "/mail/send/batch", response_body: {
        "sent" => 1,
        "failed" => 0,
        "results" => [{ "id" => "email_1", "status" => "queued" }]
      })

      result = mail.send_batch(
        emails: [{ from: "sender@example.com", to: "user@example.com", subject: "Test", html: "<p>Test</p>" }],
        project_slug: "my-project"
      )

      expect(result["sent"]).to eq(1)
    end
  end

  describe "#send_broadcast" do
    it "sends a broadcast email" do
      stub_stack0_request(:post, "/mail/send/broadcast", response_body: {
        "id" => "broadcast_123",
        "recipientCount" => 1000,
        "status" => "queued"
      })

      result = mail.send_broadcast(
        from: "sender@example.com",
        to: (1..1000).map { |i| "user#{i}@example.com" },
        subject: "Announcement",
        html: "<p>Important announcement</p>"
      )

      expect(result["recipientCount"]).to eq(1000)
    end
  end

  describe "#get" do
    it "retrieves an email by ID" do
      stub_stack0_request(:get, "/mail/email_123", response_body: {
        "id" => "email_123",
        "status" => "delivered",
        "createdAt" => "2024-01-15T10:00:00Z",
        "sentAt" => "2024-01-15T10:00:05Z"
      })

      result = mail.get("email_123")

      expect(result["id"]).to eq("email_123")
      expect(result["status"]).to eq("delivered")
      expect(result["createdAt"]).to be_a(Time)
      expect(result["sentAt"]).to be_a(Time)
    end
  end

  describe "#list" do
    it "lists emails with filters" do
      stub_stack0_request(:get, "/mail?status=delivered&limit=10", response_body: {
        "emails" => [
          { "id" => "email_1", "status" => "delivered", "createdAt" => "2024-01-15T10:00:00Z" },
          { "id" => "email_2", "status" => "delivered", "createdAt" => "2024-01-15T11:00:00Z" }
        ],
        "total" => 2
      })

      result = mail.list(status: "delivered", limit: 10)

      expect(result["emails"].length).to eq(2)
      expect(result["emails"][0]["createdAt"]).to be_a(Time)
    end

    it "lists emails with date filters" do
      stub_stack0_request(:get, "/mail?startDate=2024-01-01T00%3A00%3A00Z&endDate=2024-01-31T23%3A59%3A59Z",
                          response_body: {
                            "emails" => [],
                            "total" => 0
                          })

      result = mail.list(
        start_date: "2024-01-01T00:00:00Z",
        end_date: "2024-01-31T23:59:59Z"
      )

      expect(result["emails"]).to eq([])
    end
  end

  describe "#resend" do
    it "resends an email" do
      stub_stack0_request(:post, "/mail/email_123/resend", response_body: {
        "id" => "email_new",
        "status" => "queued"
      })

      result = mail.resend("email_123")

      expect(result["id"]).to eq("email_new")
    end
  end

  describe "#cancel" do
    it "cancels a scheduled email" do
      stub_stack0_request(:post, "/mail/email_123/cancel", response_body: {
        "success" => true
      })

      result = mail.cancel("email_123")

      expect(result["success"]).to be(true)
    end
  end

  describe "#get_analytics" do
    it "retrieves email analytics" do
      stub_stack0_request(:get, "/mail/analytics", response_body: {
        "sent" => 1000,
        "delivered" => 980,
        "opened" => 450,
        "clicked" => 120,
        "bounced" => 20,
        "unsubscribed" => 5
      })

      result = mail.get_analytics

      expect(result["sent"]).to eq(1000)
      expect(result["delivered"]).to eq(980)
    end
  end

  describe "#get_time_series_analytics" do
    it "retrieves time series analytics" do
      stub_stack0_request(:get, "/mail/analytics/timeseries?days=7", response_body: {
        "data" => [
          { "date" => "2024-01-15", "sent" => 100, "delivered" => 98 },
          { "date" => "2024-01-16", "sent" => 120, "delivered" => 118 }
        ]
      })

      result = mail.get_time_series_analytics(days: 7)

      expect(result["data"].length).to eq(2)
    end
  end

  describe "#get_hourly_analytics" do
    it "retrieves hourly analytics" do
      stub_stack0_request(:get, "/mail/analytics/hourly", response_body: {
        "data" => [
          { "hour" => 0, "sent" => 10 },
          { "hour" => 1, "sent" => 5 }
        ]
      })

      result = mail.get_hourly_analytics

      expect(result["data"].length).to eq(2)
    end
  end

  describe "#list_senders" do
    it "lists unique senders" do
      stub_stack0_request(:get, "/mail/senders", response_body: {
        "senders" => [
          { "email" => "sender1@example.com", "sentCount" => 500 },
          { "email" => "sender2@example.com", "sentCount" => 300 }
        ]
      })

      result = mail.list_senders

      expect(result["senders"].length).to eq(2)
    end

    it "searches senders" do
      stub_stack0_request(:get, "/mail/senders?search=sender1", response_body: {
        "senders" => [
          { "email" => "sender1@example.com", "sentCount" => 500 }
        ]
      })

      result = mail.list_senders(search: "sender1")

      expect(result["senders"].length).to eq(1)
    end
  end
end
