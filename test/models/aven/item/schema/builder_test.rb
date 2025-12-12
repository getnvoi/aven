# frozen_string_literal: true

require "test_helper"

class Aven::Item::Schema::BuilderTest < ActiveSupport::TestCase
  def setup
    @builder = Aven::Item::Schema::Builder.new
  end

  # Field definitions
  test "string creates string field" do
    @builder.string(:name, required: true)
    assert_equal({ type: :string, required: true }, @builder.fields[:name])
  end

  test "integer creates integer field" do
    @builder.integer(:age)
    assert_equal({ type: :integer }, @builder.fields[:age])
  end

  test "boolean creates boolean field" do
    @builder.boolean(:active, required: true)
    assert_equal({ type: :boolean, required: true }, @builder.fields[:active])
  end

  test "date creates date field with format" do
    @builder.date(:birth_date)
    assert_equal({ type: :string, format: "date" }, @builder.fields[:birth_date])
  end

  test "datetime creates datetime field with format" do
    @builder.datetime(:created_at)
    assert_equal({ type: :string, format: "date-time" }, @builder.fields[:created_at])
  end

  test "array creates array field with items type" do
    @builder.array(:tags, of: :string)
    expected = { type: :array, items: { type: :string } }
    assert_equal expected, @builder.fields[:tags]
  end

  # Embeds
  test "embeds_many creates embed with many cardinality" do
    @builder.embeds_many(:addresses) do
      string :city
      string :street
    end

    embed = @builder.embeds[:addresses]
    assert_equal :many, embed[:cardinality]
    assert_equal({ type: :string }, embed[:fields][:city])
  end

  test "embeds_one creates embed with one cardinality" do
    @builder.embeds_one(:primary_address) do
      string :city
    end

    embed = @builder.embeds[:primary_address]
    assert_equal :one, embed[:cardinality]
  end

  test "embed block supports all field types" do
    @builder.embeds_many(:test) do
      string :str
      integer :int
      boolean :bool
      date :date
      datetime :datetime
      array :arr, of: :string
    end

    fields = @builder.embeds[:test][:fields]
    assert_equal :string, fields[:str][:type]
    assert_equal :integer, fields[:int][:type]
    assert_equal :boolean, fields[:bool][:type]
    assert_equal "date", fields[:date][:format]
    assert_equal "date-time", fields[:datetime][:format]
    assert_equal :array, fields[:arr][:type]
  end

  # Links
  test "links_many creates link with many cardinality" do
    @builder.links_many(:notes, class_name: "Aven::Item")
    link = @builder.links[:notes]
    assert_equal :many, link[:cardinality]
    assert_equal "Aven::Item", link[:class_name]
  end

  test "links_one creates link with one cardinality" do
    @builder.links_one(:company, class_name: "Aven::Item")
    link = @builder.links[:company]
    assert_equal :one, link[:cardinality]
  end

  test "links supports inverse_of option" do
    @builder.links_one(:company, class_name: "Aven::Item", inverse_of: :employees)
    assert_equal :employees, @builder.links[:company][:inverse_of]
  end

  # JSON Schema generation
  test "to_json_schema returns object type" do
    schema = @builder.to_json_schema
    assert_equal "object", schema["type"]
  end

  test "to_json_schema includes properties" do
    @builder.string(:name)
    schema = @builder.to_json_schema
    assert_includes schema["properties"].keys, "name"
  end

  test "to_json_schema includes required fields" do
    @builder.string(:name, required: true)
    @builder.string(:optional)
    schema = @builder.to_json_schema
    assert_includes schema["required"], "name"
    assert_not_includes schema["required"], "optional"
  end

  test "to_json_schema converts field types correctly" do
    @builder.string(:name)
    @builder.integer(:age)
    @builder.boolean(:active)

    props = @builder.to_json_schema["properties"]
    assert_equal "string", props["name"]["type"]
    assert_equal "integer", props["age"]["type"]
    assert_equal "boolean", props["active"]["type"]
  end

  test "to_json_schema includes format for date/datetime" do
    @builder.date(:birth_date)
    @builder.datetime(:timestamp)

    props = @builder.to_json_schema["properties"]
    assert_equal "date", props["birth_date"]["format"]
    assert_equal "date-time", props["timestamp"]["format"]
  end

  test "to_json_schema includes enum constraint" do
    @builder.string(:status, enum: %w[active inactive])
    props = @builder.to_json_schema["properties"]
    assert_equal %w[active inactive], props["status"]["enum"]
  end

  test "to_json_schema includes length constraints" do
    @builder.string(:name, min_length: 1, max_length: 100)
    props = @builder.to_json_schema["properties"]
    assert_equal 1, props["name"]["minLength"]
    assert_equal 100, props["name"]["maxLength"]
  end

  test "to_json_schema includes array items" do
    @builder.array(:tags, of: :string)
    props = @builder.to_json_schema["properties"]
    assert_equal({ "type" => "string" }, props["tags"]["items"])
  end

  test "to_json_schema includes embeds_many as array" do
    @builder.embeds_many(:addresses) do
      string :city
    end

    props = @builder.to_json_schema["properties"]
    assert_equal "array", props["addresses"]["type"]
    assert_equal "object", props["addresses"]["items"]["type"]
  end

  test "to_json_schema includes embeds_one as object" do
    @builder.embeds_one(:address) do
      string :city
    end

    props = @builder.to_json_schema["properties"]
    assert_equal "object", props["address"]["type"]
  end
end
