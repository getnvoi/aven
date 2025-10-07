require "rails_helper"

RSpec.describe Sqema::WorkspaceRole, type: :model do
  describe "associations" do
    it { should belong_to(:workspace).class_name("Sqema::Workspace") }
    it { should have_many(:workspace_user_roles).class_name("Sqema::WorkspaceUserRole").dependent(:destroy) }
    it { should have_many(:workspace_users).through(:workspace_user_roles).class_name("Sqema::WorkspaceUser") }
    it { should have_many(:users).through(:workspace_users).class_name("Sqema::User") }
  end

  describe "validations" do
    it { should validate_presence_of(:label) }
    subject { create(:sqema_workspace_role) }
    it { should validate_uniqueness_of(:label).scoped_to(:workspace_id) }
  end

  describe "constants and scopes" do
    it "defines predefined roles" do
      expect(described_class::PREDEFINED_ROLES).to include("owner", "admin", "member", "viewer")
    end

    it "predefined? and custom? behave as expected" do
      ws = create(:sqema_workspace)
      r1 = create(:sqema_workspace_role, workspace: ws, label: "owner")
      r2 = create(:sqema_workspace_role, workspace: ws, label: "custom_role")

      expect(r1.predefined?).to be true
      expect(r1.custom?).to be false
      expect(r2.predefined?).to be false
      expect(r2.custom?).to be true
    end
  end
end

