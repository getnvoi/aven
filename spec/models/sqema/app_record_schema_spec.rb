require "rails_helper"

RSpec.describe Sqema::AppRecordSchema, type: :model do
  describe "associations" do
    it { should belong_to(:workspace).class_name("Sqema::Workspace") }
    it { should have_many(:app_records).class_name("Sqema::AppRecord").dependent(:destroy) }
    it { should have_many(:logs).class_name("Sqema::Log").dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:schema) }

    it "validates schema format contains type" do
      ws = create(:sqema_workspace)
      s = described_class.new(workspace: ws, schema: { "properties" => {} })
      expect(s).to be_invalid
      expect(s.errors[:schema]).to include("must include a 'type' property")
    end
  end
end
