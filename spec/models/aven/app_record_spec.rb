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
require "rails_helper"

RSpec.describe Aven::AppRecord, type: :model do
  describe "associations" do
    it { should belong_to(:app_record_schema).class_name("Aven::AppRecordSchema") }
    it { should have_many(:logs).class_name("Aven::Log").dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:data) }

    it "requires app_record_schema to exist" do
      rec = described_class.new(app_record_schema: nil, data: { "x" => 1 })
      expect(rec).not_to be_valid
      expect(rec.errors[:app_record_schema]).to include("must exist")
    end

    it "fails when app_record_schema has no schema" do
      schema = build(:aven_app_record_schema, schema: nil)
      rec = described_class.new(app_record_schema: schema, data: { "x" => 1 })
      expect(rec).not_to be_valid
      expect(rec.errors[:app_record_schema].join).to match(/schema must be present/i)
    end
  end

  it "delegates workspace from schema" do
    schema = create(:aven_app_record_schema)
    rec = create(:aven_app_record, app_record_schema: schema)
    expect(rec.workspace).to eq(schema.workspace)
  end
end
