# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_item_schemas
#
#  id           :bigint           not null, primary key
#  embeds       :jsonb            not null
#  fields       :jsonb            not null
#  links        :jsonb            not null
#  schema       :jsonb            not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_item_schemas_on_slug                   (slug)
#  index_aven_item_schemas_on_workspace_id           (workspace_id)
#  index_aven_item_schemas_on_workspace_id_and_slug  (workspace_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

module Aven
  class ItemSchemaTest < ActiveSupport::TestCase
    attr_reader :workspace

    setup do
      @workspace = aven_workspaces(:one)
    end

    # === Validations ===

    test "valid with required attributes" do
      schema = ItemSchema.new(
        workspace: workspace,
        slug: "test_object",
        schema: { "type" => "object" }
      )
      assert schema.valid?
    end

    test "invalid without slug" do
      schema = ItemSchema.new(schema: { "type" => "object" })
      assert_not schema.valid?
      assert_includes schema.errors[:slug], "can't be blank"
    end

    test "invalid without schema" do
      schema = ItemSchema.new(slug: "test")
      assert_not schema.valid?
      assert_includes schema.errors[:schema], "can't be blank"
    end

    test "invalid with duplicate slug in same workspace" do
      existing = aven_item_schemas(:custom_object)
      schema = ItemSchema.new(
        workspace: existing.workspace,
        slug: existing.slug,
        schema: { "type" => "object" }
      )
      assert_not schema.valid?
      assert_includes schema.errors[:slug], "has already been taken"
    end

    test "valid with same slug in different workspace" do
      # custom_object exists in workspace one, but also in workspace two
      # They should both be valid
      schema_one = aven_item_schemas(:custom_object)
      schema_two = aven_item_schemas(:other_workspace_schema)

      assert_equal schema_one.slug, schema_two.slug
      assert_not_equal schema_one.workspace_id, schema_two.workspace_id
      assert schema_one.valid?
      assert schema_two.valid?
    end

    test "slug format validation - lowercase with underscores" do
      valid_slugs = %w[myschema my_schema schema123 a a1 test_schema_name]
      invalid_slugs = %w[Contact MY_SCHEMA 123schema _underscore schema-dash Schema!]

      valid_slugs.each do |slug|
        schema = ItemSchema.new(workspace: workspace, slug: slug, schema: { "type" => "object" })
        assert schema.valid?, "Expected '#{slug}' to be valid"
      end

      invalid_slugs.each do |slug|
        schema = ItemSchema.new(workspace: workspace, slug: slug, schema: { "type" => "object" })
        assert_not schema.valid?, "Expected '#{slug}' to be invalid"
      end
    end

    test "schema must be a hash" do
      schema = ItemSchema.new(slug: "test", schema: "not a hash")
      assert_not schema.valid?
      assert_includes schema.errors[:schema], "must be a valid JSON object"
    end

    test "schema must have type property" do
      schema = ItemSchema.new(slug: "test", schema: { "properties" => {} })
      assert_not schema.valid?
      assert_includes schema.errors[:schema], "must include a 'type' property"
    end

    # === Workspace scoping ===

    test "scoped to workspace" do
      schemas = ItemSchema.in_workspace(workspace)
      assert schemas.all? { |s| s.workspace_id == workspace.id }
    end

    test "requires workspace" do
      schema = ItemSchema.new(
        slug: "no_workspace",
        schema: { "type" => "object" }
      )
      assert_not schema.valid?
      assert_includes schema.errors[:workspace], "must exist"
    end

    # === Interface methods ===

    test "builder returns self" do
      schema = aven_item_schemas(:custom_object)
      assert_equal schema, schema.builder
    end

    test "to_json_schema returns schema" do
      schema = aven_item_schemas(:custom_object)
      assert_equal schema.schema, schema.to_json_schema
    end

    test "fields_config returns symbolized fields" do
      schema = aven_item_schemas(:custom_object)
      fields = schema.fields_config

      assert fields.key?(:name)
      # YAML stores as strings, deep_symbolize_keys only symbolizes keys not values
      assert_equal "string", fields[:name][:type]
    end

    test "embeds_config returns symbolized embeds" do
      schema = ItemSchema.new(
        slug: "with_embeds",
        schema: { "type" => "object" },
        embeds: { "addresses" => { "cardinality" => "many" } }
      )
      embeds = schema.embeds_config

      assert embeds.key?(:addresses)
      assert_equal "many", embeds[:addresses][:cardinality]
    end

    test "links_config returns symbolized links" do
      schema = ItemSchema.new(
        slug: "with_links",
        schema: { "type" => "object" },
        links: { "company" => { "cardinality" => "one" } }
      )
      links = schema.links_config

      assert links.key?(:company)
      assert_equal "one", links[:company][:cardinality]
    end

    test "fields_config returns empty hash when nil" do
      schema = ItemSchema.new(slug: "empty", schema: { "type" => "object" })
      schema.fields = nil
      assert_equal({}, schema.fields_config)
    end

    # === Alias methods ===

    test "schema_fields is alias for fields_config" do
      schema = aven_item_schemas(:custom_object)
      assert_equal schema.fields_config, schema.schema_fields
    end

    test "schema_embeds is alias for embeds_config" do
      schema = aven_item_schemas(:custom_object)
      assert_equal schema.embeds_config, schema.schema_embeds
    end

    test "schema_links is alias for links_config" do
      schema = aven_item_schemas(:custom_object)
      assert_equal schema.links_config, schema.schema_links
    end
  end
end
