require "rails_helper"

RSpec.describe Sqema::Log, type: :model do
  describe "associations" do
    it { should belong_to(:loggable) }
    it { should belong_to(:workspace).class_name("Sqema::Workspace") }
  end

  describe "validations" do
    it { should validate_presence_of(:message) }
    it { should allow_value("debug", "info", "warn", "error", "fatal").for(:level) }
  end

  it "applies workspace from loggable if missing" do
    ws = create(:sqema_workspace)
    log = described_class.new(message: "x", loggable: ws, loggable_type: "Sqema::Workspace", loggable_id: ws.id)
    expect(log.workspace).to be_nil
    log.valid?
    expect(log.workspace).to eq(ws)
  end
end

