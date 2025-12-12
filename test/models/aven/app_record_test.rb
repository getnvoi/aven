# == Schema Information
#
# Table name: aven_app_records
#
#  id                   :bigint           not null, primary key
#  data                 :jsonb            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  app_record_schema_id :bigint           not null
#
# Indexes
#
#  index_aven_app_records_on_app_record_schema_id  (app_record_schema_id)
#  index_aven_app_records_on_data                  (data) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (app_record_schema_id => aven_app_record_schemas.id)
#
require "test_helper"

class Aven::AppRecordTest < ActiveSupport::TestCase
  # Associations
  test "belongs to app_record_schema" do
    app_record = aven_app_records(:one)
    assert_respond_to app_record, :app_record_schema
  end

  test "has many logs" do
    app_record = aven_app_records(:one)
    assert_respond_to app_record, :logs
  end

  # Validations
  test "validates presence of data" do
    app_record = Aven::AppRecord.new(app_record_schema: aven_app_record_schemas(:one), data: nil)
    assert_not app_record.valid?
    assert_includes app_record.errors[:data], "can't be blank"
  end

  test "requires app_record_schema to exist" do
    app_record = Aven::AppRecord.new(app_record_schema: nil, data: { "x" => 1 })
    assert_not app_record.valid?
    assert_includes app_record.errors[:app_record_schema], "must exist"
  end

  test "fails when app_record_schema has no schema" do
    workspace = aven_workspaces(:one)
    schema = Aven::AppRecordSchema.new(workspace: workspace, schema: nil)
    app_record = Aven::AppRecord.new(app_record_schema: schema, data: { "x" => 1 })

    assert_not app_record.valid?
    assert_match /schema must be present/i, app_record.errors[:app_record_schema].join
  end

  # Delegation
  test "delegates workspace from schema" do
    schema = aven_app_record_schemas(:one)
    app_record = aven_app_records(:one)

    assert_equal schema.workspace, app_record.workspace
  end
end
