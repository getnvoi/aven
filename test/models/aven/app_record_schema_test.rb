require "test_helper"

class Aven::AppRecordSchemaTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace" do
    schema = aven_app_record_schemas(:one)
    assert_respond_to schema, :workspace
  end

  test "has many app_records" do
    schema = aven_app_record_schemas(:one)
    assert_respond_to schema, :app_records
  end

  test "has many logs" do
    schema = aven_app_record_schemas(:one)
    assert_respond_to schema, :logs
  end

  # Validations
  test "validates presence of schema" do
    schema = Aven::AppRecordSchema.new(workspace: aven_workspaces(:one), schema: nil)
    assert_not schema.valid?
    assert_includes schema.errors[:schema], "can't be blank"
  end

  test "validates schema format contains type" do
    workspace = aven_workspaces(:one)
    schema = Aven::AppRecordSchema.new(workspace: workspace, schema: { "properties" => {} })

    assert_not schema.valid?
    assert_includes schema.errors[:schema], "must include a 'type' property"
  end
end
