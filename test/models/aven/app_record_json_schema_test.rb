require "test_helper"

class Aven::AppRecordJSONSchemaTest < ActiveSupport::TestCase
  def build_record_with_schema(schema:, data:)
    workspace = aven_workspaces(:one)
    app_schema = Aven::AppRecordSchema.create!(workspace: workspace, schema: schema)
    Aven::AppRecord.new(app_record_schema: app_schema, data: data)
  end

  # Required properties
  test "passes when required field present" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => { "name" => { "type" => "string" } },
      "required" => [ "name" ]
    }

    record = build_record_with_schema(schema: schema, data: { "name" => "Alice" })
    assert record.valid?
  end

  test "fails when required field missing" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => { "name" => { "type" => "string" } },
      "required" => [ "name" ]
    }

    record = build_record_with_schema(schema: schema, data: { "other" => 1 })
    assert_not record.valid?

    message = record.errors[:data].join
    assert_includes message, "schema validation failed"
    assert_match /Missing keys:.*name/i, message
  end

  # Optional properties
  test "allows missing optional field" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => { "nickname" => { "type" => "string" } }
    }

    record = build_record_with_schema(schema: schema, data: { "other" => true })
    assert record.valid?
  end

  # Format validations
  test "validates email format" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => { "email" => { "type" => "string", "format" => "email" } },
      "required" => [ "email" ]
    }

    valid_record = build_record_with_schema(schema: schema, data: { "email" => "user@example.com" })
    assert valid_record.valid?

    invalid_record = build_record_with_schema(schema: schema, data: { "email" => "not-an-email" })
    assert_not invalid_record.valid?
    assert_includes invalid_record.errors[:data].join, "/email"
  end

  test "validates uri format" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => { "url" => { "type" => "string", "format" => "uri" } },
      "required" => [ "url" ]
    }

    valid_record = build_record_with_schema(schema: schema, data: { "url" => "https://example.com/x" })
    assert valid_record.valid?

    invalid_record = build_record_with_schema(schema: schema, data: { "url" => "not a url" })
    assert_not invalid_record.valid?
    assert_includes invalid_record.errors[:data].join, "/url"
  end

  # Arrays
  test "passes valid arrays" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "array",
      "items" => { "type" => "integer" },
      "minItems" => 2,
      "uniqueItems" => true
    }

    record = build_record_with_schema(schema: schema, data: [ 1, 2 ])
    assert record.valid?
  end

  test "fails when array element has wrong type" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "array",
      "items" => { "type" => "integer" },
      "minItems" => 2,
      "uniqueItems" => true
    }

    record = build_record_with_schema(schema: schema, data: [ "a", 2 ])
    assert_not record.valid?
    assert_includes record.errors[:data].join, "/0"
  end

  test "fails when array is below minItems" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "array",
      "items" => { "type" => "integer" },
      "minItems" => 2,
      "uniqueItems" => true
    }

    record = build_record_with_schema(schema: schema, data: [ 1 ])
    assert_not record.valid?
    assert_match /too few elements|minimum 2/i, record.errors[:data].join
  end

  test "fails when array items are not unique" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "array",
      "items" => { "type" => "integer" },
      "minItems" => 2,
      "uniqueItems" => true
    }

    record = build_record_with_schema(schema: schema, data: [ 1, 1 ])
    assert_not record.valid?
    assert_match /must all be unique/i, record.errors[:data].join
  end

  # Combinators (anyOf)
  test "validates anyOf for code" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => {
        "code" => {
          "anyOf" => [
            { "type" => "string", "pattern" => "^[A-Z]+$" },
            { "type" => "integer" }
          ]
        }
      },
      "required" => [ "code" ]
    }

    assert build_record_with_schema(schema: schema, data: { "code" => "ABC" }).valid?
    assert build_record_with_schema(schema: schema, data: { "code" => 123 }).valid?

    invalid_record = build_record_with_schema(schema: schema, data: { "code" => "abc" })
    assert_not invalid_record.valid?
    assert_includes invalid_record.errors[:data].join, "/code"
  end

  # Combinators (allOf)
  test "validates allOf for age bounds" do
    schema = {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => {
        "age" => {
          "allOf" => [
            { "type" => "integer", "minimum" => 18 },
            { "type" => "integer", "maximum" => 65 }
          ]
        }
      },
      "required" => [ "age" ]
    }

    assert build_record_with_schema(schema: schema, data: { "age" => 30 }).valid?

    too_young = build_record_with_schema(schema: schema, data: { "age" => 10 })
    assert_not too_young.valid?
    assert_includes too_young.errors[:data].join, "/age"
    assert_match /less than 18/i, too_young.errors[:data].join

    too_old = build_record_with_schema(schema: schema, data: { "age" => 70 })
    assert_not too_old.valid?
    assert_includes too_old.errors[:data].join, "/age"
    assert_match /greater than 65/i, too_old.errors[:data].join
  end
end
