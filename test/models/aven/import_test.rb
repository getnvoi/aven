# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_imports
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  error_message   :text
#  errors_log      :jsonb
#  imported_count  :integer          default(0)
#  processed_count :integer          default(0)
#  skipped_count   :integer          default(0)
#  source          :string           not null
#  started_at      :datetime
#  status          :string           default("pending"), not null
#  total_count     :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  workspace_id    :bigint           not null
#
# Indexes
#
#  index_aven_imports_on_source        (source)
#  index_aven_imports_on_status        (status)
#  index_aven_imports_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

class Aven::ImportTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace" do
    import = aven_imports(:pending_google)
    assert_respond_to import, :workspace
    assert_equal aven_workspaces(:one), import.workspace
  end

  test "has many entries" do
    import = aven_imports(:pending_google)
    assert_respond_to import, :entries
    assert_includes import.entries, aven_import_entries(:google_entry_one)
  end

  test "destroys entries on destroy" do
    import = aven_imports(:pending_google)
    entry_ids = import.entries.pluck(:id)
    assert entry_ids.any?

    import.destroy!
    assert_empty Aven::Import::Entry.where(id: entry_ids)
  end

  # Validations
  test "requires source" do
    import = Aven::Import.new(workspace: aven_workspaces(:one), status: "pending")
    assert_not import.valid?
    assert_includes import.errors[:source], "can't be blank"
  end

  test "requires valid source" do
    import = Aven::Import.new(workspace: aven_workspaces(:one), source: "invalid", status: "pending")
    assert_not import.valid?
    assert import.errors[:source].any? { |e| e.include?("is not included") }
  end

  test "requires status" do
    import = Aven::Import.new(workspace: aven_workspaces(:one), source: "google_contacts", status: nil)
    assert_not import.valid?
    assert_includes import.errors[:status], "can't be blank"
  end

  test "requires valid status" do
    import = Aven::Import.new(workspace: aven_workspaces(:one), source: "google_contacts", status: "invalid")
    assert_not import.valid?
    assert import.errors[:status].any? { |e| e.include?("is not included") }
  end

  test "valid with google_contacts source" do
    import = Aven::Import.new(workspace: aven_workspaces(:one), source: "google_contacts")
    assert import.valid?
  end

  test "valid with gmail_emails source" do
    import = Aven::Import.new(workspace: aven_workspaces(:one), source: "gmail_emails")
    assert import.valid?
  end

  # Scopes
  test "in_progress scope includes pending, fetching, processing" do
    pending = aven_imports(:pending_google)
    processing = aven_imports(:processing_gmail)
    completed = aven_imports(:completed_import)
    failed = aven_imports(:failed_import)

    in_progress = Aven::Import.in_progress
    assert_includes in_progress, pending
    assert_includes in_progress, processing
    assert_not_includes in_progress, completed
    assert_not_includes in_progress, failed
  end

  test "recent scope orders by created_at desc" do
    imports = Aven::Import.recent.limit(2)
    assert imports.first.created_at >= imports.last.created_at
  end

  test "by_source scope filters by source" do
    google = Aven::Import.by_source("google_contacts")
    assert_includes google, aven_imports(:pending_google)
    assert_not_includes google, aven_imports(:processing_gmail)
  end

  # Status methods
  test "in_progress? returns true for pending" do
    assert aven_imports(:pending_google).in_progress?
  end

  test "in_progress? returns true for processing" do
    assert aven_imports(:processing_gmail).in_progress?
  end

  test "in_progress? returns false for completed" do
    assert_not aven_imports(:completed_import).in_progress?
  end

  test "in_progress? returns false for failed" do
    assert_not aven_imports(:failed_import).in_progress?
  end

  test "completed? returns true for completed status" do
    assert aven_imports(:completed_import).completed?
    assert_not aven_imports(:pending_google).completed?
  end

  test "failed? returns true for failed status" do
    assert aven_imports(:failed_import).failed?
    assert_not aven_imports(:pending_google).failed?
  end

  # Progress
  test "progress_percentage returns 0 when total_count is 0" do
    import = aven_imports(:pending_google)
    assert_equal 0, import.progress_percentage
  end

  test "progress_percentage calculates correctly" do
    import = aven_imports(:processing_gmail)
    assert_equal 50, import.progress_percentage
  end

  test "progress_percentage returns 100 when complete" do
    import = aven_imports(:completed_import)
    assert_equal 100, import.progress_percentage
  end

  # State transitions
  test "mark_fetching! updates status and started_at" do
    import = aven_imports(:pending_google)
    assert_nil import.started_at

    import.mark_fetching!(total: 100)

    assert_equal "fetching", import.status
    assert_equal 100, import.total_count
    assert_not_nil import.started_at
  end

  test "mark_processing! updates status" do
    import = aven_imports(:pending_google)
    import.mark_processing!
    assert_equal "processing", import.status
  end

  test "increment_processed! increments processed_count" do
    import = aven_imports(:pending_google)
    assert_equal 0, import.processed_count

    import.increment_processed!
    assert_equal 1, import.reload.processed_count
  end

  test "increment_imported! increments imported_count" do
    import = aven_imports(:pending_google)
    assert_equal 0, import.imported_count

    import.increment_imported!
    assert_equal 1, import.reload.imported_count
  end

  test "increment_skipped! increments skipped_count" do
    import = aven_imports(:pending_google)
    assert_equal 0, import.skipped_count

    import.increment_skipped!
    assert_equal 1, import.reload.skipped_count
  end

  test "mark_completed! updates status and completed_at" do
    import = aven_imports(:processing_gmail)
    assert_nil import.completed_at

    import.mark_completed!

    assert_equal "completed", import.status
    assert_not_nil import.completed_at
  end

  test "mark_failed! updates status, error_message, and completed_at" do
    import = aven_imports(:processing_gmail)
    import.mark_failed!("Something went wrong")

    assert_equal "failed", import.status
    assert_equal "Something went wrong", import.error_message
    assert_not_nil import.completed_at
  end

  test "log_error appends to errors_log" do
    import = aven_imports(:pending_google)
    assert_empty import.errors_log

    import.log_error("First error")
    import.log_error("Second error")

    assert_equal 2, import.reload.errors_log.size
    assert_equal "First error", import.errors_log.first["message"]
    assert_equal "Second error", import.errors_log.last["message"]
  end

  # TenantModel integration
  test "includes TenantModel" do
    import = aven_imports(:pending_google)
    assert import.workspace_scoped?
  end

  test "in_workspace scope works" do
    workspace = aven_workspaces(:one)
    imports = Aven::Import.in_workspace(workspace)

    assert_includes imports, aven_imports(:pending_google)
    assert_not_includes imports, aven_imports(:other_workspace_import)
  end
end
