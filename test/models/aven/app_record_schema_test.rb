# == Schema Information
#
# Table name: aven_app_record_schemas
#
#  id           :bigint           not null, primary key
#  schema       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_app_record_schemas_on_schema        (schema) USING gin
#  index_aven_app_record_schemas_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
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
