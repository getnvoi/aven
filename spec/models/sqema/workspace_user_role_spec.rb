require "rails_helper"

RSpec.describe Sqema::WorkspaceUserRole, type: :model do
  describe "associations" do
    it { should belong_to(:workspace_user).class_name("Sqema::WorkspaceUser") }
    it { should belong_to(:workspace_role).class_name("Sqema::WorkspaceRole") }
  end

  describe "validations" do
    subject { create(:sqema_workspace_user_role) }
    it { should validate_uniqueness_of(:workspace_user_id).scoped_to(:workspace_role_id) }
  end

  describe "delegates and scopes" do
    let(:ws) { create(:sqema_workspace) }
    let(:user) { create(:sqema_user, username: "alice", email: "alice@example.com", auth_tenant: "test") }
    let(:wu) { create(:sqema_workspace_user, workspace: ws, user: user) }
    let(:role) { create(:sqema_workspace_role, workspace: ws, label: "member", description: "Member role") }
    let!(:wur) { create(:sqema_workspace_user_role, workspace_user: wu, workspace_role: role) }

    it "delegates attributes" do
      expect(wur.workspace).to eq(ws)
      expect(wur.label).to eq("member")
      expect(wur.description).to eq("Member role")
      expect(wur.user).to eq(user)
      expect(wur.email).to eq("alice@example.com")
      expect(wur.username).to eq("alice")
    end

    it "filters by workspace and role label" do
      expect(described_class.for_workspace(ws)).to include(wur)
      expect(described_class.with_role("member")).to include(wur)
      expect(described_class.with_role("owner")).not_to include(wur)
    end
  end
end

