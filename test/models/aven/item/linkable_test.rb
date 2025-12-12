# frozen_string_literal: true

require "test_helper"

class Aven::Item::LinkableTest < ActiveSupport::TestCase
  def setup
    @workspace = aven_workspaces(:one)
    @contact = aven_items(:contact_one)
    @company = aven_items(:company_one)
    @note = aven_items(:note_one)
  end

  # Associations
  test "has_many outgoing_links" do
    assert_respond_to @contact, :outgoing_links
    assert_includes @contact.outgoing_links.map(&:target), @company
  end

  test "has_many incoming_links" do
    assert_respond_to @company, :incoming_links
    assert_includes @company.incoming_links.map(&:source), @contact
  end

  test "outgoing_links dependent destroy" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    Aven::ItemLink.create!(source: contact, target: @company, relation: "company")

    link_count = Aven::ItemLink.where(source: contact).count
    assert_equal 1, link_count

    contact.destroy

    assert_equal 0, Aven::ItemLink.where(source_id: contact.id).count
  end

  test "incoming_links dependent destroy" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    Aven::ItemLink.create!(source: @contact, target: contact, relation: "related")

    link_count = Aven::ItemLink.where(target: contact).count
    assert_equal 1, link_count

    contact.destroy

    assert_equal 0, Aven::ItemLink.where(target_id: contact.id).count
  end

  # Callbacks
  test "after_save :persist_pending_links is registered" do
    callbacks = Aven::Item._save_callbacks.map(&:filter)
    assert_includes callbacks, :persist_pending_links
  end

  # persist_pending_link_ids - links_many
  test "creates links for new ids" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.note_ids = [@note.id]
    contact.save!

    assert_includes contact.reload.note_ids, @note.id
  end

  test "removes links for removed ids" do
    contact = aven_items(:contact_one)
    initial_note_ids = contact.note_ids
    assert_includes initial_note_ids, @note.id

    contact.note_ids = []
    contact.save!

    assert_not_includes contact.reload.note_ids, @note.id
  end

  test "preserves existing links not in pending" do
    # contact_one already has note_one linked
    note_two = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "Second note" })
    @contact.note_ids = [@note.id, note_two.id]
    @contact.save!

    assert_includes @contact.reload.note_ids, @note.id
    assert_includes @contact.reload.note_ids, note_two.id
  end

  test "handles empty array for links_many" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.note_ids = []
    assert_nothing_raised { contact.save! }
  end

  # persist_pending_link_ids - links_one
  test "creates link for links_one" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.company_id = @company.id
    contact.save!

    assert_equal @company.id, contact.reload.company_id
  end

  test "replaces existing link for links_one" do
    company_two = Aven::Item.create!(workspace: @workspace, schema_slug: "company", data: { name: "New Corp" })
    @contact.company_id = company_two.id
    @contact.save!

    assert_equal company_two.id, @contact.reload.company_id
  end

  test "removes link when links_one set to nil" do
    @contact.company_id = nil
    @contact.save!

    assert_nil @contact.reload.company_id
  end

  test "handles nil for links_one" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.company_id = nil
    assert_nothing_raised { contact.save! }
  end

  # process_link_attributes - links_many
  test "creates linked items from attributes" do
    @contact.notes_attributes = [{ body: "New note" }]
    @contact.save!

    new_note = @contact.notes.find { |n| n.data["body"] == "New note" }
    assert_not_nil new_note
  end

  test "updates existing linked items" do
    @contact.notes_attributes = [{ id: @note.id, body: "Updated body" }]
    @contact.save!

    assert_equal "Updated body", @note.reload.data["body"]
  end

  test "destroys linked items with _destroy flag" do
    initial_count = @contact.notes.count
    @contact.notes_attributes = [{ id: @note.id, _destroy: "1" }]
    @contact.save!

    assert_equal initial_count - 1, @contact.reload.notes.count
    assert_not_includes @contact.note_ids, @note.id
  end

  test "handles mixed create, update, destroy" do
    new_note = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "To update" })
    Aven::ItemLink.create!(source: @contact, target: new_note, relation: "notes")

    @contact.notes_attributes = [
      { id: @note.id, _destroy: "1" },
      { id: new_note.id, body: "Updated" },
      { body: "Brand new" }
    ]
    @contact.save!

    notes = @contact.reload.notes
    assert_not notes.any? { |n| n.id == @note.id }
    assert notes.any? { |n| n.data["body"] == "Updated" }
    assert notes.any? { |n| n.data["body"] == "Brand new" }
  end

  # process_link_attributes - links_one
  test "creates linked item for links_one from attributes" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.company_attributes = { name: "New Company" }
    contact.save!

    assert_not_nil contact.reload.company
    assert_equal "New Company", contact.company.data["name"]
  end

  test "updates existing linked item for links_one" do
    @contact.company_attributes = { id: @company.id, name: "Updated Company" }
    @contact.save!

    assert_equal "Updated Company", @company.reload.data["name"]
  end

  test "destroys linked item for links_one with _destroy" do
    @contact.company_attributes = { id: @company.id, _destroy: "1" }
    @contact.save!

    assert_nil @contact.reload.company_id
  end

  test "ignores blank attributes for links_one" do
    initial_company_id = @contact.company_id
    @contact.company_attributes = {}
    @contact.save!

    assert_equal initial_company_id, @contact.reload.company_id
  end

  # Edge cases
  test "does not persist links for new record until saved" do
    contact = Aven::Item.new(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.company_id = @company.id

    assert_equal 0, Aven::ItemLink.where(source: contact).count
  end

  test "handles invalid target id gracefully" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.company_id = -999
    # Should not raise, just won't create the link
    assert_nothing_raised { contact.save! }
  end

  test "clears pending links after save" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.company_id = @company.id
    contact.save!

    pending = contact.instance_variable_get(:@_pending_links)
    assert_nil pending
  end

  test "clears pending link attrs after save" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })
    contact.notes_attributes = [{ body: "Test" }]
    contact.save!

    pending = contact.instance_variable_get(:@_pending_link_attrs)
    assert_nil pending
  end

  # Link queries through Schemaed
  test "links_many returns ActiveRecord relation" do
    notes = @contact.notes
    assert_kind_of ActiveRecord::Relation, notes
  end

  test "links_one returns single item" do
    company = @contact.company
    assert_kind_of Aven::Item, company
    assert_equal @company, company
  end

  test "links_one returns nil when no link" do
    contact = aven_items(:contact_two)
    assert_nil contact.company
  end
end
