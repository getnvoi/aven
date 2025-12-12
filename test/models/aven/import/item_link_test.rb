# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_import_item_links
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  entry_id   :bigint           not null
#  item_id    :bigint           not null
#
# Indexes
#
#  index_aven_import_item_links_on_entry_id              (entry_id)
#  index_aven_import_item_links_on_entry_id_and_item_id  (entry_id,item_id) UNIQUE
#  index_aven_import_item_links_on_item_id               (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (entry_id => aven_import_entries.id)
#  fk_rails_...  (item_id => aven_items.id)
#
require "test_helper"

class Aven::Import::ItemLinkTest < ActiveSupport::TestCase
  # Associations
  test "belongs to entry" do
    link = aven_import_item_links(:completed_link)
    assert_respond_to link, :entry
    assert_equal aven_import_entries(:completed_entry), link.entry
  end

  test "belongs to item" do
    link = aven_import_item_links(:completed_link)
    assert_respond_to link, :item
    assert_equal aven_items(:contact_one), link.item
  end

  # Validations
  test "requires unique entry_id and item_id combination" do
    existing = aven_import_item_links(:completed_link)
    duplicate = Aven::Import::ItemLink.new(
      entry: existing.entry,
      item: existing.item
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:entry_id].any?
  end

  test "allows same entry with different item" do
    # This would require creating a new entry first
    entry = aven_import_entries(:google_entry_one)
    item = aven_items(:contact_two)

    link = Aven::Import::ItemLink.new(entry:, item:)
    assert link.valid?
  end

  test "allows same item with different entry" do
    entry = aven_import_entries(:google_entry_two)
    item = aven_items(:contact_one)

    link = Aven::Import::ItemLink.new(entry:, item:)
    assert link.valid?
  end

  # Delegation
  test "delegates import to entry" do
    link = aven_import_item_links(:completed_link)
    assert_equal link.entry.import, link.import
  end

  test "delegates workspace to entry" do
    link = aven_import_item_links(:completed_link)
    assert_equal link.entry.workspace, link.workspace
  end

  test "delegates schema_slug to item" do
    link = aven_import_item_links(:completed_link)
    assert_equal link.item.schema_slug, link.schema_slug
  end
end
