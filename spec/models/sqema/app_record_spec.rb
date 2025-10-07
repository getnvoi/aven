require "rails_helper"

RSpec.describe Sqema::AppRecord, type: :model do
  describe "associations" do
    it { should belong_to(:app_record_schema).class_name("Sqema::AppRecordSchema") }
    it { should have_many(:logs).class_name("Sqema::Log").dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:data) }

    it "requires app_record_schema to exist" do
      rec = described_class.new(app_record_schema: nil, data: { "x" => 1 })
      expect(rec).not_to be_valid
      expect(rec.errors[:app_record_schema]).to include("must exist")
    end

    it "fails when app_record_schema has no schema" do
      schema = build(:sqema_app_record_schema, schema: nil)
      rec = described_class.new(app_record_schema: schema, data: { "x" => 1 })
      expect(rec).not_to be_valid
      expect(rec.errors[:app_record_schema].join).to match(/schema must be present/i)
    end
  end

  it "delegates workspace from schema" do
    schema = create(:sqema_app_record_schema)
    rec = create(:sqema_app_record, app_record_schema: schema)
    expect(rec.workspace).to eq(schema.workspace)
  end
end
