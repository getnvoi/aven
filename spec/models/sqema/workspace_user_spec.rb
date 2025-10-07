require "rails_helper"

RSpec.describe Sqema::WorkspaceUser, type: :model do
  describe "associations" do
    it { should belong_to(:user).class_name("Sqema::User") }
    it { should belong_to(:workspace).class_name("Sqema::Workspace") }
    it { should have_many(:workspace_user_roles).class_name("Sqema::WorkspaceUserRole").dependent(:destroy) }
    it { should have_many(:workspace_roles).through(:workspace_user_roles).class_name("Sqema::WorkspaceRole") }
  end

  describe "validations" do
    subject { create(:sqema_workspace_user) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:workspace_id) }
  end

  describe "role helpers" do
    let(:workspace) { create(:sqema_workspace) }
    let(:user) { create(:sqema_user, username: "tester", email: "tester@example.com", auth_tenant: "test") }
    let(:workspace_user) { create(:sqema_workspace_user, user:, workspace:) }

    it "returns empty roles initially" do
      expect(workspace_user.roles).to eq([])
    end

    it "adds and lists roles" do
      workspace_user.add_role("owner")
      workspace_user.add_role("admin")
      expect(workspace_user.roles).to contain_exactly("owner", "admin")
      expect(workspace_user).to be_has_role("owner")
    end

    it "removes roles" do
      workspace_user.add_role("member")
      expect { workspace_user.remove_role("member") }.to change { workspace_user.roles.include?("member") }.from(true).to(false)
    end
  end
end

