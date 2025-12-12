# frozen_string_literal: true

require "test_helper"

class Aven::External::GmailClientTest < ActiveSupport::TestCase
  setup do
    @access_token = "test_access_token"
    @client = Aven::External::GmailClient.new(@access_token)
  end

  # Initialization
  test "initializes with access token" do
    assert_instance_of Aven::External::GmailClient, @client
  end

  test "initializes with exclude_emails" do
    client = Aven::External::GmailClient.new(@access_token, exclude_emails: ["me@example.com"])
    assert_instance_of Aven::External::GmailClient, client
  end

  # extract_email_addresses
  test "extract_email_addresses returns addresses from messages" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "John Doe <john@example.com>" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal 1, result[:emails_scanned]
    assert_equal 1, result[:addresses].size
    assert_equal "john@example.com", result[:addresses].first["email"]
    assert_equal "John Doe", result[:addresses].first["name"]
  end

  test "extract_email_addresses handles multiple headers" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "sender@example.com" },
      { "name" => "To", "value" => "recipient@example.com" },
      { "name" => "Cc", "value" => "cc@example.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal 3, result[:addresses].size
    emails = result[:addresses].map { |a| a["email"] }
    assert_includes emails, "sender@example.com"
    assert_includes emails, "recipient@example.com"
    assert_includes emails, "cc@example.com"
  end

  test "extract_email_addresses deduplicates addresses" do
    stub_messages_list([{ "id" => "msg1" }, { "id" => "msg2" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "same@example.com" }
    ])
    stub_message_detail("msg2", headers: [
      { "name" => "From", "value" => "same@example.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal 2, result[:emails_scanned]
    assert_equal 1, result[:addresses].size
  end

  test "extract_email_addresses respects max_emails limit" do
    stub_messages_list([{ "id" => "msg1" }, { "id" => "msg2" }, { "id" => "msg3" }])
    stub_message_detail("msg1", headers: [{ "name" => "From", "value" => "a@example.com" }])
    stub_message_detail("msg2", headers: [{ "name" => "From", "value" => "b@example.com" }])

    result = @client.extract_email_addresses(max_emails: 2)

    assert_equal 2, result[:emails_scanned]
  end

  test "extract_email_addresses calls progress callback" do
    stub_messages_list([{ "id" => "msg1" }, { "id" => "msg2" }])
    stub_message_detail("msg1", headers: [{ "name" => "From", "value" => "a@example.com" }])
    stub_message_detail("msg2", headers: [{ "name" => "From", "value" => "b@example.com" }])

    progress_calls = []
    @client.extract_email_addresses(max_emails: 10) { |count| progress_calls << count }

    assert_equal [1, 2], progress_calls
  end

  # Ignored addresses
  test "ignores noreply addresses" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "noreply@example.com" },
      { "name" => "To", "value" => "valid@example.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal 1, result[:addresses].size
    assert_equal "valid@example.com", result[:addresses].first["email"]
  end

  test "ignores newsletter addresses" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "newsletter@company.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_empty result[:addresses]
  end

  test "ignores excluded emails" do
    client = Aven::External::GmailClient.new(@access_token, exclude_emails: ["me@example.com"])

    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "me@example.com" },
      { "name" => "To", "value" => "other@example.com" }
    ])

    result = client.extract_email_addresses(max_emails: 10)

    assert_equal 1, result[:addresses].size
    assert_equal "other@example.com", result[:addresses].first["email"]
  end

  test "ignores github noreply domain" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "user@noreply.github.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_empty result[:addresses]
  end

  test "ignores substack domain" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "author@substack.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_empty result[:addresses]
  end

  # Email parsing
  test "parses Name <email> format" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "John Doe <john@example.com>" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal "john@example.com", result[:addresses].first["email"]
    assert_equal "John Doe", result[:addresses].first["name"]
  end

  test "parses bare email format" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "john@example.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal "john@example.com", result[:addresses].first["email"]
    assert_nil result[:addresses].first["name"]
  end

  test "parses quoted name format" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "\"John Doe\" <john@example.com>" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal "john@example.com", result[:addresses].first["email"]
  end

  test "parses multiple addresses in header" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "To", "value" => "one@example.com, two@example.com, Three <three@example.com>" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal 3, result[:addresses].size
  end

  test "extracts domain from email" do
    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "user@company.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal "company.com", result[:addresses].first["domain"]
  end

  # fetch_into_import
  test "fetch_into_import creates entries for import" do
    import = aven_imports(:processing_gmail)
    import.entries.destroy_all

    stub_messages_list([{ "id" => "msg1" }])
    stub_message_detail("msg1", headers: [
      { "name" => "From", "value" => "Test User <test@example.com>" }
    ])

    assert_difference "import.entries.count", 1 do
      result = @client.fetch_into_import(import, max_emails: 10)
      assert_equal 1, result[:emails_scanned]
    end

    entry = import.entries.first
    assert_equal "test@example.com", entry.data["email"]
    assert_equal "Test User", entry.data["name"]
    assert_equal "example.com", entry.data["domain"]
  end

  # Error handling
  test "raises Error on messages list API failure" do
    stub_request(:get, %r{gmail.googleapis.com/gmail/v1/users/me/messages})
      .to_return(status: 500, body: "Server Error")

    assert_raises(Aven::External::GmailClient::Error) do
      @client.extract_email_addresses(max_emails: 10)
    end
  end

  test "continues on individual message fetch failure" do
    stub_messages_list([{ "id" => "msg1" }, { "id" => "msg2" }])

    stub_request(:get, "https://gmail.googleapis.com/gmail/v1/users/me/messages/msg1?format=metadata")
      .to_return(status: 500, body: { error: "Error" }.to_json, headers: { "Content-Type" => "application/json" })
    stub_message_detail("msg2", headers: [
      { "name" => "From", "value" => "valid@example.com" }
    ])

    result = @client.extract_email_addresses(max_emails: 10)

    # First message fails but we still try, second succeeds
    # emails_scanned counts attempts, not successes
    assert_equal 1, result[:addresses].size
  end

  # Pagination
  test "handles pagination" do
    # First page
    stub_request(:get, %r{gmail.googleapis.com/gmail/v1/users/me/messages})
      .with(query: hash_excluding("pageToken"))
      .to_return(
        status: 200,
        body: { "messages" => [{ "id" => "msg1" }], "nextPageToken" => "page2" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Second page
    stub_request(:get, %r{gmail.googleapis.com/gmail/v1/users/me/messages})
      .with(query: hash_including("pageToken" => "page2"))
      .to_return(
        status: 200,
        body: { "messages" => [{ "id" => "msg2" }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_message_detail("msg1", headers: [{ "name" => "From", "value" => "first@example.com" }])
    stub_message_detail("msg2", headers: [{ "name" => "From", "value" => "second@example.com" }])

    result = @client.extract_email_addresses(max_emails: 10)

    assert_equal 2, result[:addresses].size
  end

  private

    def stub_messages_list(messages, next_page_token: nil)
      body = { "messages" => messages }
      body["nextPageToken"] = next_page_token if next_page_token

      stub_request(:get, %r{gmail.googleapis.com/gmail/v1/users/me/messages})
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_message_detail(message_id, headers:)
      stub_request(:get, "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{message_id}?format=metadata")
        .to_return(
          status: 200,
          body: { "payload" => { "headers" => headers } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
end
