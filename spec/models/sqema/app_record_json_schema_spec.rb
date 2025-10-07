require "rails_helper"

RSpec.describe "Sqema::AppRecord JSON Schema validation", type: :model do
  def build_record_with_schema(schema:, data:)
    ws = create(:sqema_workspace)
    s = create(:sqema_app_record_schema, workspace: ws, schema: schema)
    Sqema::AppRecord.new(app_record_schema: s, data: data)
  end

  describe "required properties" do
    let(:schema) do
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => { "name" => { "type" => "string" } },
        "required" => ["name"]
      }
    end

    it "passes when required field present" do
      rec = build_record_with_schema(schema: schema, data: { "name" => "Alice" })
      expect(rec).to be_valid
    end

    it "fails when required field missing" do
      rec = build_record_with_schema(schema: schema, data: { "other" => 1 })
      expect(rec).not_to be_valid
      msg = rec.errors[:data].join
      expect(msg).to include("schema validation failed")
      expect(msg).to match(/Missing keys:.*name/i)
    end
  end

  describe "optional properties (not required)" do
    let(:schema) do
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => { "nickname" => { "type" => "string" } }
      }
    end

    it "allows missing optional field" do
      rec = build_record_with_schema(schema: schema, data: { "other" => true })
      expect(rec).to be_valid
    end
  end

  describe "formats" do
    it "validates email format" do
      schema = {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => { "email" => { "type" => "string", "format" => "email" } },
        "required" => ["email"]
      }

      ok = build_record_with_schema(schema: schema, data: { "email" => "user@example.com" })
      expect(ok).to be_valid

      bad = build_record_with_schema(schema: schema, data: { "email" => "not-an-email" })
      expect(bad).not_to be_valid
      expect(bad.errors[:data].join).to include("/email")
    end

    it "validates uri format" do
      schema = {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
        "properties" => { "url" => { "type" => "string", "format" => "uri" } },
        "required" => ["url"]
      }

      ok = build_record_with_schema(schema: schema, data: { "url" => "https://example.com/x" })
      expect(ok).to be_valid

      bad = build_record_with_schema(schema: schema, data: { "url" => "not a url" })
      expect(bad).not_to be_valid
      expect(bad.errors[:data].join).to include("/url")
    end
  end

  describe "arrays" do
    let(:schema) do
      {
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "array",
        "items" => { "type" => "integer" },
        "minItems" => 2,
        "uniqueItems" => true
      }
    end

    it "passes valid arrays" do
      rec = build_record_with_schema(schema: schema, data: [1, 2])
      expect(rec).to be_valid
    end

    it "fails when element has wrong type" do
      rec = build_record_with_schema(schema: schema, data: ["a", 2])
      expect(rec).not_to be_valid
      expect(rec.errors[:data].join).to include("/0")
    end

    it "fails when below minItems" do
      rec = build_record_with_schema(schema: schema, data: [1])
      expect(rec).not_to be_valid
      expect(rec.errors[:data].join).to match(/too few elements|minimum 2/i)
    end

    it "fails when not unique" do
      rec = build_record_with_schema(schema: schema, data: [1, 1])
      expect(rec).not_to be_valid
      expect(rec.errors[:data].join).to match(/must all be unique/i)
    end
  end

  describe "combinators (allOf/anyOf)" do
    it "validates anyOf for code" do
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
        "required" => ["code"]
      }

      expect(build_record_with_schema(schema: schema, data: { "code" => "ABC" })).to be_valid
      expect(build_record_with_schema(schema: schema, data: { "code" => 123 })).to be_valid

      bad = build_record_with_schema(schema: schema, data: { "code" => "abc" })
      expect(bad).not_to be_valid
      expect(bad.errors[:data].join).to include("/code")
    end

    it "validates allOf for age bounds" do
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
        "required" => ["age"]
      }

      expect(build_record_with_schema(schema: schema, data: { "age" => 30 })).to be_valid

      too_young = build_record_with_schema(schema: schema, data: { "age" => 10 })
      expect(too_young).not_to be_valid
      expect(too_young.errors[:data].join).to include("/age").and match(/less than 18/i)

      too_old = build_record_with_schema(schema: schema, data: { "age" => 70 })
      expect(too_old).not_to be_valid
      expect(too_old.errors[:data].join).to include("/age").and match(/greater than 65/i)
    end
  end
end
