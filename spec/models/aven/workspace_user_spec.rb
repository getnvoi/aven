# == Schema Information
#
# Table name: aven_workspace_users
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  idx_aven_workspace_users_on_user_workspace  (user_id,workspace_id) UNIQUE
#  index_aven_workspace_users_on_user_id       (user_id)
#  index_aven_workspace_users_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "rails_helper"

RSpec.describe Aven::WorkspaceUser, type: :model do
  describe "associations" do
    it { should belong_to(:user).class_name("Aven::User") }
    it { should belong_to(:workspace).class_name("Aven::Workspace") }
    it { should have_many(:workspace_user_roles).class_name("Aven::WorkspaceUserRole").dependent(:destroy) }
    it { should have_many(:workspace_roles).through(:workspace_user_roles).class_name("Aven::WorkspaceRole") }
  end

  describe "validations" do
    subject { create(:aven_workspace_user) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:workspace_id) }
  end

  describe "role helpers" do
    let(:workspace) { create(:aven_workspace) }
    let(:user) { create(:aven_user, email: "tester@example.com", auth_tenant: "test") }
    let(:workspace_user) { create(:aven_workspace_user, user:, workspace:) }

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

