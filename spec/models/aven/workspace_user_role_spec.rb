# == Schema Information
#
# Table name: aven_workspace_user_roles
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  workspace_role_id :bigint
#  workspace_user_id :bigint
#
# Indexes
#
#  idx_aven_ws_user_roles_on_role_user                   (workspace_role_id,workspace_user_id) UNIQUE
#  index_aven_workspace_user_roles_on_workspace_role_id  (workspace_role_id)
#  index_aven_workspace_user_roles_on_workspace_user_id  (workspace_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_role_id => aven_workspace_roles.id)
#  fk_rails_...  (workspace_user_id => aven_workspace_users.id)
#
require "rails_helper"

RSpec.describe Aven::WorkspaceUserRole, type: :model do
  describe "associations" do
    it { should belong_to(:workspace_user).class_name("Aven::WorkspaceUser") }
    it { should belong_to(:workspace_role).class_name("Aven::WorkspaceRole") }
  end

  describe "validations" do
    subject { create(:aven_workspace_user_role) }
    it { should validate_uniqueness_of(:workspace_user_id).scoped_to(:workspace_role_id) }
  end

  describe "delegates and scopes" do
    let(:ws) { create(:aven_workspace) }
    let(:user) { create(:aven_user, email: "alice@example.com", auth_tenant: "test") }
    let(:wu) { create(:aven_workspace_user, workspace: ws, user: user) }
    let(:role) { create(:aven_workspace_role, workspace: ws, label: "member", description: "Member role") }
    let!(:wur) { create(:aven_workspace_user_role, workspace_user: wu, workspace_role: role) }

    it "delegates attributes" do
      expect(wur.workspace).to eq(ws)
      expect(wur.label).to eq("member")
      expect(wur.description).to eq("Member role")
      expect(wur.user).to eq(user)
      expect(wur.email).to eq("alice@example.com")
    end

    it "filters by workspace and role label" do
      expect(described_class.for_workspace(ws)).to include(wur)
      expect(described_class.with_role("member")).to include(wur)
      expect(described_class.with_role("owner")).not_to include(wur)
    end
  end
end

