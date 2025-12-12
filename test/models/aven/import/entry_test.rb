# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_import_entries
#
#  id         :bigint           not null, primary key
#  data       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  import_id  :bigint           not null
#
# Indexes
#
#  index_aven_import_entries_on_data       (data) USING gin
#  index_aven_import_entries_on_import_id  (import_id)
#
# Foreign Keys
#
#  fk_rails_...  (import_id => aven_imports.id)
#
require "test_helper"

class Aven::Import::EntryTest < ActiveSupport::TestCase
  # Associations
  test "belongs to import" do
    entry = aven_import_entries(:google_entry_one)
    assert_respond_to entry, :import
    assert_equal aven_imports(:pending_google), entry.import
  end

  test "has many item_links" do
    entry = aven_import_entries(:completed_entry)
    assert_respond_to entry, :item_links
    assert_includes entry.item_links, aven_import_item_links(:completed_link)
  end

  test "has many items through item_links" do
    entry = aven_import_entries(:completed_entry)
    assert_respond_to entry, :items
    assert_includes entry.items, aven_items(:contact_one)
  end

  test "destroys item_links on destroy" do
    entry = aven_import_entries(:completed_entry)
    link_ids = entry.item_links.pluck(:id)
    assert link_ids.any?

    entry.destroy!
    assert_empty Aven::Import::ItemLink.where(id: link_ids)
  end

  # Validations
  test "requires data" do
    entry = Aven::Import::Entry.new(import: aven_imports(:pending_google), data: nil)
    assert_not entry.valid?
    assert_includes entry.errors[:data], "can't be blank"
  end

  test "valid with data" do
    entry = Aven::Import::Entry.new(
      import: aven_imports(:pending_google),
      data: { "email" => "test@example.com" }
    )
    assert entry.valid?
  end

  # Scopes
  test "linked scope returns entries with item_link" do
    linked = Aven::Import::Entry.linked
    assert_includes linked, aven_import_entries(:completed_entry)
    assert_not_includes linked, aven_import_entries(:google_entry_one)
  end

  test "unlinked scope returns entries without item_link" do
    unlinked = Aven::Import::Entry.unlinked
    assert_includes unlinked, aven_import_entries(:google_entry_one)
    assert_not_includes unlinked, aven_import_entries(:completed_entry)
  end

  # Delegation
  test "delegates workspace to import" do
    entry = aven_import_entries(:google_entry_one)
    assert_equal entry.import.workspace, entry.workspace
  end

  # Methods
  test "linked? returns true when item_link present" do
    assert aven_import_entries(:completed_entry).linked?
  end

  test "linked? returns false when item_link absent" do
    assert_not aven_import_entries(:google_entry_one).linked?
  end

  test "link_to_item! creates item_link" do
    entry = aven_import_entries(:google_entry_one)
    item = aven_items(:contact_two)

    assert_not entry.linked?
    entry.link_to_item!(item)

    assert entry.reload.linked?
    assert_includes entry.items, item
  end

  test "link_to_item! adds another link" do
    entry = aven_import_entries(:completed_entry)
    original_count = entry.item_links.count
    new_item = aven_items(:contact_two)

    entry.link_to_item!(new_item)

    assert_equal original_count + 1, entry.reload.item_links.count
    assert_includes entry.items, new_item
  end

  test "link_to_item! raises on duplicate entry+item" do
    entry = aven_import_entries(:completed_entry)
    existing_item = entry.items.first

    assert_raises(ActiveRecord::RecordInvalid) do
      entry.link_to_item!(existing_item)
    end
  end

  # Data access
  test "data is accessible as hash" do
    entry = aven_import_entries(:google_entry_one)
    assert_equal "Alice", entry.data["first_name"]
    assert_equal "alice@example.com", entry.data["email"]
  end
end
