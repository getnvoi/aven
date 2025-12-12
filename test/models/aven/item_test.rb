# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_items
#
#  id           :bigint           not null, primary key
#  data         :jsonb            not null
#  deleted_at   :datetime
#  schema_slug  :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_items_on_data          (data) USING gin
#  index_aven_items_on_deleted_at    (deleted_at)
#  index_aven_items_on_schema_slug   (schema_slug)
#  index_aven_items_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

class Aven::ItemTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace" do
    item = aven_items(:contact_one)
    assert_respond_to item, :workspace
    assert_equal aven_workspaces(:one), item.workspace
  end

  test "has many outgoing_links" do
    item = aven_items(:contact_one)
    assert_respond_to item, :outgoing_links
  end

  test "has many incoming_links" do
    item = aven_items(:contact_one)
    assert_respond_to item, :incoming_links
  end

  # Validations
  test "requires schema_slug" do
    item = Aven::Item.new(workspace: aven_workspaces(:one), data: { "name" => "Test" })
    assert_not item.valid?
    assert_includes item.errors[:schema_slug], "can't be blank"
  end

  test "requires data" do
    item = Aven::Item.new(workspace: aven_workspaces(:one), schema_slug: "contact", data: nil)
    assert_not item.valid?
    assert_includes item.errors[:data], "can't be blank"
  end

  test "valid with schema_slug and data" do
    item = Aven::Item.new(workspace: aven_workspaces(:one), schema_slug: "contact", data: { "first_name" => "Test" })
    assert item.valid?
  end

  # Scopes
  test "active scope excludes deleted items" do
    items = Aven::Item.active
    assert_not_includes items, aven_items(:deleted_item)
    assert_includes items, aven_items(:contact_one)
  end

  test "deleted scope includes only deleted items" do
    items = Aven::Item.deleted
    assert_includes items, aven_items(:deleted_item)
    assert_not_includes items, aven_items(:contact_one)
  end

  test "by_schema scope filters by schema_slug" do
    items = Aven::Item.by_schema("contact")
    assert_includes items, aven_items(:contact_one)
    assert_not_includes items, aven_items(:company_one)
  end

  test "recent scope orders by created_at desc" do
    items = Aven::Item.recent.limit(2)
    assert_equal items.first.created_at, items.last.created_at
  end

  # Soft delete
  test "soft_delete! sets deleted_at" do
    item = aven_items(:contact_one)
    assert_nil item.deleted_at
    item.soft_delete!
    assert_not_nil item.reload.deleted_at
  end

  test "restore! clears deleted_at" do
    item = aven_items(:deleted_item)
    assert_not_nil item.deleted_at
    item.restore!
    assert_nil item.reload.deleted_at
  end

  test "deleted? returns true when deleted_at is present" do
    assert aven_items(:deleted_item).deleted?
    assert_not aven_items(:contact_one).deleted?
  end

  # Schema class methods
  test "schema_class_for returns schema class" do
    schema_class = Aven::Item.schema_class_for("contact")
    assert_equal Aven::Item::Schemas::Contact, schema_class
  end

  test "schema_class_for returns nil for unknown schema" do
    schema_class = Aven::Item.schema_class_for("unknown")
    assert_nil schema_class
  end

  test "schema_for returns code class when available" do
    schema = Aven::Item.schema_for("contact")
    assert_equal Aven::Item::Schemas::Contact, schema
  end

  test "schema_for returns ItemSchema when no code class" do
    workspace = aven_workspaces(:one)
    schema = Aven::Item.schema_for("custom_object", workspace:)
    assert_instance_of Aven::ItemSchema, schema
    assert_equal "custom_object", schema.slug
  end

  test "schema_for raises when no class or DB schema" do
    workspace = aven_workspaces(:one)
    assert_raises(ActiveRecord::RecordNotFound) do
      Aven::Item.schema_for("nonexistent", workspace:)
    end
  end

  test "schema_class returns schema class for item" do
    item = aven_items(:contact_one)
    assert_equal Aven::Item::Schemas::Contact, item.schema_class
  end

  test "schema_builder returns builder for item" do
    item = aven_items(:contact_one)
    assert_instance_of Aven::Item::Schema::Builder, item.schema_builder
  end

  # Resolved schema
  test "resolved_schema returns code class when available" do
    item = aven_items(:contact_one)
    assert_equal Aven::Item::Schemas::Contact, item.resolved_schema
  end

  test "resolved_schema returns ItemSchema when no code class" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "custom_object",
      data: { "name" => "Test" }
    )
    assert_instance_of Aven::ItemSchema, item.resolved_schema
  end

  test "resolved_schema raises when not found" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "nonexistent",
      data: {}
    )
    assert_raises(ActiveRecord::RecordNotFound) do
      item.resolved_schema
    end
  end

  # TenantModel integration
  test "includes TenantModel" do
    item = aven_items(:contact_one)
    assert item.workspace_scoped?
    assert_respond_to item, :workspace
  end

  test "in_workspace scope works" do
    workspace = aven_workspaces(:one)
    items = Aven::Item.in_workspace(workspace)
    assert_includes items, aven_items(:contact_one)
    assert_not_includes items, aven_items(:other_workspace_item)
  end

  # Dynamic accessors
  test "dynamic field getter reads from data" do
    item = aven_items(:contact_one)
    assert_equal "John", item.first_name
  end

  test "dynamic field setter writes to data" do
    item = aven_items(:contact_one)
    item.first_name = "Updated"
    assert_equal "Updated", item.data["first_name"]
  end

  test "respond_to? returns true for schema fields" do
    item = aven_items(:contact_one)
    assert item.respond_to?(:first_name)
    assert item.respond_to?(:first_name=)
  end

  # JSON Schema validation
  test "validates data against DB schema" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "custom_object",
      data: { "name" => "Test Object" }
    )
    assert item.valid?
  end

  test "rejects invalid data per DB schema" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "custom_object",
      data: { "value" => 123 } # missing required "name"
    )
    assert_not item.valid?
    assert item.errors[:data].any? { |e| e.include?("schema validation failed") }
  end

  test "rejects wrong data type per DB schema" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "custom_object",
      data: { "name" => "Test", "value" => "not an integer" }
    )
    assert_not item.valid?
    assert item.errors[:data].any? { |e| e.include?("schema validation failed") }
  end

  test "validates data against code schema" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "contact",
      data: { "first_name" => "John" }
    )
    assert item.valid?
  end

  test "adds schema not found error when schema missing" do
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "nonexistent",
      data: { "test" => "data" }
    )
    assert_not item.valid?
    assert item.errors[:schema_slug].any? { |e| e.include?("not found") }
  end

  test "skips validation when data is blank" do
    # This tests the guard clause - validation should skip, not error
    item = Aven::Item.new(
      workspace: aven_workspaces(:one),
      schema_slug: "custom_object",
      data: {}
    )
    # Will still fail data presence validation, but not schema validation
    assert_not item.valid?
    assert_includes item.errors[:data], "can't be blank"
  end
end
