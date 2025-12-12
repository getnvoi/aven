# frozen_string_literal: true

require "test_helper"

# Integration tests for nested attributes on Items
# Tests the full flow: setter -> process -> save -> persistence
class Aven::Item::NestedAttributesTest < ActiveSupport::TestCase
  def setup
    @workspace = aven_workspaces(:one)
    @contact = aven_items(:contact_one)
    @company = aven_items(:company_one)
    @note = aven_items(:note_one)
  end

  # ===========================================
  # Embed nested attributes (addresses_attributes=)
  # ===========================================

  test "embed attributes: creates new embeds with array format" do
    @contact.addresses_attributes = [
      { city: "San Francisco", street: "123 Main St" },
      { city: "Los Angeles", street: "456 Oak Ave" }
    ]
    @contact.save!

    assert_equal 2, @contact.reload.addresses.length
    assert @contact.addresses.all? { |a| a.id.present? }
    assert_equal ["San Francisco", "Los Angeles"], @contact.addresses.map(&:city)
  end

  test "embed attributes: creates new embeds with hash format (Rails form style)" do
    @contact.addresses_attributes = {
      "0" => { city: "SF", street: "Main" },
      "1" => { city: "LA", street: "Oak" }
    }
    @contact.save!

    assert_equal 2, @contact.reload.addresses.length
  end

  test "embed attributes: updates existing embed by id" do
    # First create an embed
    @contact.addresses = [{ city: "Original City" }]
    @contact.save!
    embed_id = @contact.reload.addresses.first.id

    # Now update via nested attributes
    @contact.addresses_attributes = [{ id: embed_id, city: "Updated City" }]
    @contact.save!

    assert_equal 1, @contact.reload.addresses.length
    assert_equal embed_id, @contact.addresses.first.id
    assert_equal "Updated City", @contact.addresses.first.city
  end

  test "embed attributes: destroys embed with _destroy='1'" do
    @contact.addresses = [{ city: "To Delete" }, { city: "To Keep" }]
    @contact.save!
    delete_id = @contact.addresses.find { |a| a.city == "To Delete" }.id
    keep_id = @contact.addresses.find { |a| a.city == "To Keep" }.id

    @contact.addresses_attributes = [{ id: delete_id, _destroy: "1" }]
    @contact.save!

    assert_equal 1, @contact.reload.addresses.length
    assert_equal keep_id, @contact.addresses.first.id
  end

  test "embed attributes: destroys embed with _destroy=true" do
    @contact.addresses = [{ city: "To Delete" }]
    @contact.save!
    embed_id = @contact.addresses.first.id

    @contact.addresses_attributes = [{ id: embed_id, _destroy: true }]
    @contact.save!

    assert_equal 0, @contact.reload.addresses.length
  end

  test "embed attributes: ignores _destroy='0'" do
    @contact.addresses = [{ city: "Keep Me" }]
    @contact.save!
    embed_id = @contact.addresses.first.id

    @contact.addresses_attributes = [{ id: embed_id, _destroy: "0", city: "Still Here" }]
    @contact.save!

    assert_equal 1, @contact.reload.addresses.length
    assert_equal "Still Here", @contact.addresses.first.city
  end

  test "embed attributes: mixed create, update, destroy in one call" do
    @contact.addresses = [
      { city: "Update Me" },
      { city: "Delete Me" }
    ]
    @contact.save!
    update_id = @contact.addresses.find { |a| a.city == "Update Me" }.id
    delete_id = @contact.addresses.find { |a| a.city == "Delete Me" }.id

    @contact.addresses_attributes = [
      { id: update_id, city: "Updated" },
      { id: delete_id, _destroy: "1" },
      { city: "Brand New" }
    ]
    @contact.save!

    addresses = @contact.reload.addresses
    assert_equal 2, addresses.length
    assert addresses.any? { |a| a.city == "Updated" }
    assert addresses.any? { |a| a.city == "Brand New" }
    assert_not addresses.any? { |a| a.city == "Delete Me" }
  end

  test "embed attributes: preserves other fields when updating" do
    @contact.addresses = [{ city: "SF", street: "123 Main", zip: "94102" }]
    @contact.save!
    embed_id = @contact.addresses.first.id

    # Only update city, other fields should remain
    @contact.addresses_attributes = [{ id: embed_id, city: "San Francisco" }]
    @contact.save!

    addr = @contact.reload.addresses.first
    assert_equal "San Francisco", addr.city
    assert_equal "123 Main", addr.street
    assert_equal "94102", addr.zip
  end

  test "embed attributes: ignores new embeds with _destroy flag" do
    @contact.addresses_attributes = [
      { city: "Keep This" },
      { city: "Ignore This", _destroy: "1" }
    ]
    @contact.save!

    # Only the one without _destroy should be created
    assert_equal 1, @contact.reload.addresses.length
    assert_equal "Keep This", @contact.addresses.first.city
  end

  # ===========================================
  # Link nested attributes (notes_attributes=)
  # ===========================================

  test "link attributes: creates new linked items" do
    initial_count = Aven::Item.by_schema("note").count

    @contact.notes_attributes = [{ body: "New Note 1" }, { body: "New Note 2" }]
    @contact.save!

    assert_equal initial_count + 2, Aven::Item.by_schema("note").count
    assert_equal 2, @contact.reload.notes.select { |n| n.data["body"].start_with?("New Note") }.count
  end

  test "link attributes: creates linked items with correct workspace" do
    @contact.notes_attributes = [{ body: "Test Note" }]
    @contact.save!

    new_note = @contact.notes.find { |n| n.data["body"] == "Test Note" }
    assert_equal @workspace.id, new_note.workspace_id
  end

  test "link attributes: updates existing linked items by id" do
    original_body = @note.data["body"]

    @contact.notes_attributes = [{ id: @note.id, body: "Updated Note Body" }]
    @contact.save!

    assert_equal "Updated Note Body", @note.reload.data["body"]
  end

  test "link attributes: removes link with _destroy (does not delete target)" do
    initial_note_count = Aven::Item.by_schema("note").count
    assert_includes @contact.note_ids, @note.id

    @contact.notes_attributes = [{ id: @note.id, _destroy: "1" }]
    @contact.save!

    # Link should be removed
    assert_not_includes @contact.reload.note_ids, @note.id
    # But note should still exist
    assert_equal initial_note_count, Aven::Item.by_schema("note").count
    assert Aven::Item.exists?(@note.id)
  end

  test "link attributes: mixed operations on links" do
    note2 = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "Note 2" })
    Aven::ItemLink.create!(source: @contact, target: note2, relation: "notes")

    @contact.notes_attributes = [
      { id: @note.id, _destroy: "1" },         # Remove link to note_one
      { id: note2.id, body: "Updated Note 2" }, # Update note2
      { body: "Brand New Note" }                # Create new note
    ]
    @contact.save!

    notes = @contact.reload.notes
    assert_not notes.any? { |n| n.id == @note.id }
    assert notes.any? { |n| n.data["body"] == "Updated Note 2" }
    assert notes.any? { |n| n.data["body"] == "Brand New Note" }
  end

  # ===========================================
  # links_one nested attributes (company_attributes=)
  # ===========================================

  test "links_one attributes: creates new linked item" do
    contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Test" })

    contact.company_attributes = { name: "New Company Inc" }
    contact.save!

    assert_not_nil contact.reload.company
    assert_equal "New Company Inc", contact.company.data["name"]
    assert_equal @workspace.id, contact.company.workspace_id
  end

  test "links_one attributes: updates existing linked item" do
    @contact.company_attributes = { id: @company.id, name: "Updated Corp" }
    @contact.save!

    assert_equal "Updated Corp", @company.reload.data["name"]
    assert_equal @company.id, @contact.reload.company_id
  end

  test "links_one attributes: removes link with _destroy" do
    assert_not_nil @contact.company_id

    @contact.company_attributes = { id: @company.id, _destroy: "1" }
    @contact.save!

    assert_nil @contact.reload.company_id
    # Company still exists
    assert Aven::Item.exists?(@company.id)
  end

  test "links_one attributes: replaces existing link when creating new" do
    old_company_id = @contact.company_id

    @contact.company_attributes = { name: "Brand New Company" }
    @contact.save!

    assert_not_equal old_company_id, @contact.reload.company_id
    assert_equal "Brand New Company", @contact.company.data["name"]
  end

  test "links_one attributes: ignores blank attributes" do
    old_company_id = @contact.company_id

    @contact.company_attributes = {}
    @contact.save!

    assert_equal old_company_id, @contact.reload.company_id
  end

  # ===========================================
  # Edge cases and Rails form compatibility
  # ===========================================

  test "handles string keys from Rails params" do
    @contact.addresses_attributes = {
      "0" => { "city" => "SF", "street" => "Main St" }
    }
    @contact.save!

    assert_equal 1, @contact.reload.addresses.length
    assert_equal "SF", @contact.addresses.first.city
  end

  test "handles symbol keys" do
    @contact.addresses_attributes = [{ city: "SF", street: "Main" }]
    @contact.save!

    assert_equal "SF", @contact.reload.addresses.first.city
  end

  test "handles empty array gracefully" do
    @contact.addresses_attributes = []
    assert_nothing_raised { @contact.save! }
  end

  test "handles empty hash gracefully" do
    @contact.addresses_attributes = {}
    assert_nothing_raised { @contact.save! }
  end

  test "multiple nested attribute assignments before save" do
    @contact.addresses_attributes = [{ city: "First" }]
    @contact.addresses_attributes = [{ city: "Second" }]
    @contact.save!

    # Both assignments are processed (appended)
    assert_equal 2, @contact.reload.addresses.length
    cities = @contact.addresses.map(&:city)
    assert_includes cities, "First"
    assert_includes cities, "Second"
  end

  test "nested attributes work on new (unsaved) items" do
    contact = Aven::Item.new(workspace: @workspace, schema_slug: "contact", data: { first_name: "New" })
    contact.addresses_attributes = [{ city: "SF" }]
    contact.save!

    assert_equal 1, contact.reload.addresses.length
    assert_equal "SF", contact.addresses.first.city
  end

  # ===========================================
  # Double nested attributes (contact => company => notes)
  # ===========================================

  test "double nested: updates company's notes through company_attributes" do
    company_note = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "Company Note" })
    Aven::ItemLink.create!(source: @company, target: company_note, relation: "notes")

    @contact.company_attributes = {
      id: @company.id,
      name: "Updated Acme",
      notes_attributes: [{ id: company_note.id, body: "Updated Company Note" }]
    }
    @contact.save!

    assert_equal "Updated Acme", @company.reload.data["name"]
    assert_equal "Updated Company Note", company_note.reload.data["body"]
  end

  test "double nested: creates new notes for company through company_attributes" do
    initial_count = Aven::Item.by_schema("note").count

    @contact.company_attributes = {
      id: @company.id,
      notes_attributes: [{ body: "New Note via Contact" }]
    }
    @contact.save!

    assert_equal initial_count + 1, Aven::Item.by_schema("note").count
    new_note = @company.reload.notes.find { |n| n.data["body"] == "New Note via Contact" }
    assert_not_nil new_note
  end

  test "double nested: deletes company notes through company_attributes" do
    company_note = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "To Delete" })
    Aven::ItemLink.create!(source: @company, target: company_note, relation: "notes")

    @contact.company_attributes = {
      id: @company.id,
      notes_attributes: [{ id: company_note.id, _destroy: "1" }]
    }
    @contact.save!

    assert_not_includes @company.reload.note_ids, company_note.id
  end

  test "double nested: creates company with notes in one operation" do
    new_contact = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "New Person" })

    new_contact.company_attributes = {
      name: "Brand New Corp",
      notes_attributes: [
        { body: "First note" },
        { body: "Second note" }
      ]
    }
    new_contact.save!

    new_company = new_contact.reload.company
    assert_not_nil new_company
    assert_equal "Brand New Corp", new_company.data["name"]
    assert_equal 2, new_company.notes.count
    assert_includes new_company.notes.map { |n| n.data["body"] }, "First note"
    assert_includes new_company.notes.map { |n| n.data["body"] }, "Second note"
  end

  test "double nested: mixed create, update, destroy at nested level" do
    note1 = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "Note 1" })
    note2 = Aven::Item.create!(workspace: @workspace, schema_slug: "note", data: { body: "Note 2" })
    Aven::ItemLink.create!(source: @company, target: note1, relation: "notes")
    Aven::ItemLink.create!(source: @company, target: note2, relation: "notes")

    @contact.company_attributes = {
      id: @company.id,
      notes_attributes: [
        { id: note1.id, _destroy: "1" },
        { id: note2.id, body: "Updated Note 2" },
        { body: "Brand New Note" }
      ]
    }
    @contact.save!

    @company.reload
    assert_not_includes @company.note_ids, note1.id
    assert_includes @company.notes.map { |n| n.data["body"] }, "Updated Note 2"
    assert_includes @company.notes.map { |n| n.data["body"] }, "Brand New Note"
  end
end
