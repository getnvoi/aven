# == Schema Information
#
# Table name: aven_logs
#
#  id            :bigint           not null, primary key
#  level         :string           default("info"), not null
#  loggable_type :string           not null
#  message       :text             not null
#  metadata      :jsonb
#  state         :string
#  state_machine :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  loggable_id   :bigint           not null
#  run_id        :string
#  workspace_id  :bigint           not null
#
# Indexes
#
#  idx_aven_logs_on_loggable_run_state_created_at  (loggable_type,loggable_id,run_id,state,created_at)
#  index_aven_logs_on_created_at                   (created_at)
#  index_aven_logs_on_level                        (level)
#  index_aven_logs_on_loggable                     (loggable_type,loggable_id)
#  index_aven_logs_on_workspace_id                 (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "rails_helper"

RSpec.describe Aven::Log, type: :model do
  describe "associations" do
    it { should belong_to(:loggable) }
    it { should belong_to(:workspace).class_name("Aven::Workspace") }
  end

  describe "validations" do
    it { should validate_presence_of(:message) }
    it { should allow_value("debug", "info", "warn", "error", "fatal").for(:level) }
  end

  it "applies workspace from loggable if missing" do
    ws = create(:aven_workspace)
    log = described_class.new(message: "x", loggable: ws, loggable_type: "Aven::Workspace", loggable_id: ws.id)
    expect(log.workspace).to be_nil
    log.valid?
    expect(log.workspace).to eq(ws)
  end
end

