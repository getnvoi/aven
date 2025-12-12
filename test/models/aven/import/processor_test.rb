# frozen_string_literal: true

require "test_helper"

class Aven::Import::ProcessorTest < ActiveSupport::TestCase
  setup do
    @import = aven_imports(:pending_google)
    @processor = Aven::Import::Processor.new(@import)
  end

  # Initialization
  test "initializes with import" do
    assert_equal @import, @processor.import
  end

  # Basic flow
  test "run marks import as processing" do
    @processor.run
    assert_equal "completed", @import.reload.status
  end

  test "run processes unlinked entries" do
    # Create fresh entries
    @import.entries.destroy_all
    @import.entries.create!(data: { "email" => "new@example.com", "first_name" => "New" })

    assert_difference "Aven::Item.count", 1 do
      @processor.run
    end
  end

  test "run increments processed_count for each entry" do
    @import.entries.destroy_all
    @import.entries.create!(data: { "email" => "a@example.com" })
    @import.entries.create!(data: { "email" => "b@example.com" })
    @import.update!(total_count: 2)

    @processor.run
    assert_equal 2, @import.reload.processed_count
  end

  test "run marks import as completed on success" do
    @processor.run
    assert @import.reload.completed?
    assert_not_nil @import.completed_at
  end

  # Error handling
  test "run marks import as failed on error" do
    # Force an error by mocking
    def @processor.process_entry(_entry)
      raise StandardError, "Test error"
    end

    assert_raises(StandardError) do
      @processor.run
    end

    assert @import.reload.failed?
    assert_equal "Test error", @import.error_message
  end

  # Skipping entries
  test "skips entries without email" do
    @import.entries.destroy_all
    entry = @import.entries.create!(data: { "first_name" => "No Email" })

    @processor.run

    assert_not entry.reload.linked?
    assert_equal 1, @import.reload.skipped_count
  end

  test "skips duplicate emails" do
    # contact_one fixture has john@example.com
    @import.entries.destroy_all
    entry = @import.entries.create!(data: { "email" => "john@example.com", "first_name" => "Duplicate" })

    @processor.run

    assert_not entry.reload.linked?
    assert_equal 1, @import.reload.skipped_count
  end

  # Creating items
  test "creates item with correct schema_slug for google_contacts" do
    @import.entries.destroy_all
    @import.entries.create!(data: { "email" => "unique@example.com", "first_name" => "Test" })

    @processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "unique@example.com")
    assert_not_nil item
    assert_equal "contact", item.schema_slug
  end

  test "creates item with correct schema_slug for gmail_emails" do
    import = aven_imports(:processing_gmail)
    import.entries.destroy_all
    import.entries.create!(data: { "email" => "gmail_unique@example.com", "name" => "Gmail Test" })

    processor = Aven::Import::Processor.new(import)
    processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "gmail_unique@example.com")
    assert_not_nil item
    assert_equal "contact", item.schema_slug
  end

  test "links entry to created item" do
    @import.entries.destroy_all
    entry = @import.entries.create!(data: { "email" => "linked@example.com", "first_name" => "Linked" })

    @processor.run

    assert entry.reload.linked?
    assert_equal "linked@example.com", entry.items.first.data["email"]
  end

  test "increments imported_count on success" do
    @import.entries.destroy_all
    @import.entries.create!(data: { "email" => "success@example.com" })

    @processor.run
    assert_equal 1, @import.reload.imported_count
  end

  # Data transformation - Google Contacts
  test "builds google contact data correctly" do
    @import.entries.destroy_all
    @import.entries.create!(data: {
      "first_name" => "Alice",
      "last_name" => "Smith",
      "email" => "alice@test.com",
      "phone" => "+1234567890"
    })

    @processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "alice@test.com")
    assert_equal "Alice", item.data["first_name"]
    assert_equal "Smith", item.data["last_name"]
    assert_equal "+1234567890", item.data["phone"]
  end

  test "defaults first_name to Unknown when blank" do
    @import.entries.destroy_all
    @import.entries.create!(data: { "email" => "no_name@test.com" })

    @processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "no_name@test.com")
    assert_equal "Unknown", item.data["first_name"]
  end

  # Data transformation - Gmail
  test "parses name from gmail data" do
    import = aven_imports(:processing_gmail)
    import.entries.destroy_all
    import.entries.create!(data: { "email" => "gmail_name@test.com", "name" => "John Doe" })

    processor = Aven::Import::Processor.new(import)
    processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "gmail_name@test.com")
    assert_equal "John", item.data["first_name"]
    assert_equal "Doe", item.data["last_name"]
  end

  test "parses name from email when name is blank" do
    import = aven_imports(:processing_gmail)
    import.entries.destroy_all
    import.entries.create!(data: { "email" => "john.smith@test.com" })

    processor = Aven::Import::Processor.new(import)
    processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "john.smith@test.com")
    assert_equal "John", item.data["first_name"]
    assert_equal "Smith", item.data["last_name"]
  end

  test "handles single-part email local name" do
    import = aven_imports(:processing_gmail)
    import.entries.destroy_all
    import.entries.create!(data: { "email" => "admin@test.com" })

    processor = Aven::Import::Processor.new(import)
    processor.run

    item = Aven::Item.find_by("data->>'email' = ?", "admin@test.com")
    assert_equal "Admin", item.data["first_name"]
    assert_equal "Contact", item.data["last_name"]
  end

  # Error logging
  test "logs errors for invalid records" do
    # Create an entry that would fail validation (somehow)
    @import.entries.destroy_all
    @import.entries.create!(data: { "email" => "" }) # blank email, will be skipped

    @processor.run

    assert @import.reload.errors_log.any?
  end
end
