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
require "rails_helper"

RSpec.describe Aven::AppRecordSchema, type: :model do
  describe "associations" do
    it { should belong_to(:workspace).class_name("Aven::Workspace") }
    it { should have_many(:app_records).class_name("Aven::AppRecord").dependent(:destroy) }
    it { should have_many(:logs).class_name("Aven::Log").dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:schema) }

    it "validates schema format contains type" do
      ws = create(:aven_workspace)
      s = described_class.new(workspace: ws, schema: { "properties" => {} })
      expect(s).to be_invalid
      expect(s.errors[:schema]).to include("must include a 'type' property")
    end
  end
end
