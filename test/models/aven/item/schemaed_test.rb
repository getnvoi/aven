# frozen_string_literal: true

require "test_helper"

class Aven::Item::SchemaedTest < ActiveSupport::TestCase
  def setup
    @workspace = aven_workspaces(:one)
    @item = Aven::Item.new(workspace: @workspace, schema_slug: "contact", data: {})
  end

  # Schema accessors
  test "schema_fields returns fields from schema class" do
    assert_includes @item.schema_fields.keys, :first_name
    assert_includes @item.schema_fields.keys, :last_name
  end

  test "schema_fields raises when no schema found" do
    item = Aven::Item.new(workspace: @workspace, schema_slug: "unknown", data: {})
    assert_raises(ActiveRecord::RecordNotFound) { item.schema_fields }
  end

  test "schema_embeds returns embeds from schema class" do
    assert_includes @item.schema_embeds.keys, :addresses
    assert_includes @item.schema_embeds.keys, :phones
  end

  test "schema_embeds raises when no schema found" do
    item = Aven::Item.new(workspace: @workspace, schema_slug: "unknown", data: {})
    assert_raises(ActiveRecord::RecordNotFound) { item.schema_embeds }
  end

  test "schema_links returns links from schema class" do
    assert_includes @item.schema_links.keys, :company
    assert_includes @item.schema_links.keys, :notes
  end

  test "schema_links raises when no schema found" do
    item = Aven::Item.new(workspace: @workspace, schema_slug: "unknown", data: {})
    assert_raises(ActiveRecord::RecordNotFound) { item.schema_links }
  end

  test "json_schema returns JSON schema from schema class" do
    schema = @item.json_schema
    assert_equal "object", schema["type"]
    assert_includes schema["properties"].keys, "first_name"
  end

  test "json_schema raises when no schema found" do
    item = Aven::Item.new(workspace: @workspace, schema_slug: "unknown", data: {})
    assert_raises(ActiveRecord::RecordNotFound) { item.json_schema }
  end

  # Dynamic field accessors
  test "getter reads from data hash" do
    @item.data["first_name"] = "John"
    assert_equal "John", @item.first_name
  end

  test "getter returns nil for unset fields" do
    assert_nil @item.phone
  end

  test "setter writes to data hash" do
    @item.first_name = "Jane"
    assert_equal "Jane", @item.data["first_name"]
  end

  test "setter handles nil values" do
    @item.first_name = "Jane"
    @item.first_name = nil
    assert_nil @item.data["first_name"]
  end

  test "respond_to? returns true for schema fields" do
    assert @item.respond_to?(:first_name)
    assert @item.respond_to?(:first_name=)
  end

  test "respond_to? returns false for non-schema fields" do
    assert_not @item.respond_to?(:random_field)
  end

  # Dynamic embed accessors
  test "embeds_many getter returns array of Embed objects" do
    @item.data["addresses"] = [{ "city" => "SF" }, { "city" => "LA" }]
    assert @item.addresses.all? { |a| a.is_a?(Aven::Item::Embed) }
    assert_equal %w[SF LA], @item.addresses.map(&:city)
  end

  test "embeds_many getter returns empty array when no data" do
    assert_equal [], @item.addresses
  end

  test "embeds_many getter caches the result" do
    @item.data["addresses"] = [{ "city" => "SF" }]
    first_call = @item.addresses
    second_call = @item.addresses
    assert_equal first_call.object_id, second_call.object_id
  end

  test "embeds_many setter accepts array of hashes" do
    @item.addresses = [{ city: "SF" }, { city: "LA" }]
    assert_equal [{ city: "SF" }, { city: "LA" }], @item.data["addresses"]
  end

  test "embeds_many setter accepts array of Embed objects" do
    embed = Aven::Item::Embed.new(city: "SF")
    @item.addresses = [embed]
    assert_equal [{ "city" => "SF" }], @item.data["addresses"]
  end

  test "embeds_many setter clears cache" do
    @item.data["addresses"] = [{ "city" => "SF" }]
    first_addresses = @item.addresses
    @item.addresses = [{ city: "LA" }]
    assert_equal "LA", @item.addresses.first.city
    assert_not_equal first_addresses.object_id, @item.addresses.object_id
  end

  test "build_* helper returns new Embed with generated id" do
    embed = @item.build_address
    assert_instance_of Aven::Item::Embed, embed
    assert_match(/\A[0-9a-f-]{36}\z/, embed.id)
  end

  test "*_attributes= responds" do
    assert @item.respond_to?(:addresses_attributes=)
  end

  test "*_attributes= sets embeds from attributes hash" do
    @item.addresses_attributes = { "0" => { city: "SF" }, "1" => { city: "LA" } }
    assert_equal 2, @item.data["addresses"].length
  end

  # Dynamic link accessors
  test "links_one *_id getter returns nil when not persisted" do
    assert_nil @item.company_id
  end

  test "links_one *_id= setter stores pending link" do
    company = aven_items(:company_one)
    @item.company_id = company.id
    pending = @item.instance_variable_get(:@_pending_links)
    assert_equal company.id, pending[:company]
  end

  test "links_many *_ids getter returns empty array when not persisted" do
    assert_equal [], @item.note_ids
  end

  test "links_many *_ids= setter stores pending link ids" do
    note = aven_items(:note_one)
    @item.note_ids = [note.id]
    pending = @item.instance_variable_get(:@_pending_links)
    assert_equal [note.id], pending[:notes]
  end

  test "links_many *_ids= rejects blank ids" do
    note = aven_items(:note_one)
    @item.note_ids = [note.id, "", nil]
    pending = @item.instance_variable_get(:@_pending_links)
    assert_equal [note.id], pending[:notes]
  end

  # Persisted link queries
  test "links_one getter returns linked item when persisted" do
    item = aven_items(:contact_one)
    company = item.company
    assert_equal aven_items(:company_one), company
  end

  test "links_one getter returns nil when no link" do
    item = aven_items(:contact_two)
    assert_nil item.company
  end

  test "links_one *_id getter returns id of linked item" do
    item = aven_items(:contact_one)
    assert_equal aven_items(:company_one).id, item.company_id
  end

  test "links_many getter returns linked items" do
    item = aven_items(:contact_one)
    notes = item.notes
    assert_includes notes, aven_items(:note_one)
  end

  test "links_many getter returns empty relation when no links" do
    item = aven_items(:contact_two)
    assert item.notes.empty?
  end

  test "links_many *_ids getter returns array of ids" do
    item = aven_items(:contact_one)
    assert_includes item.note_ids, aven_items(:note_one).id
  end
end
