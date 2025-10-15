# == Schema Information
#
# Table name: aven_workspace_roles
#
#  id           :bigint           not null, primary key
#  description  :string
#  label        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint
#
# Indexes
#
#  idx_aven_workspace_roles_on_ws_label        (workspace_id,label) UNIQUE
#  index_aven_workspace_roles_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "rails_helper"

RSpec.describe Aven::WorkspaceRole, type: :model do
  describe "associations" do
    it { should belong_to(:workspace).class_name("Aven::Workspace") }
    it { should have_many(:workspace_user_roles).class_name("Aven::WorkspaceUserRole").dependent(:destroy) }
    it { should have_many(:workspace_users).through(:workspace_user_roles).class_name("Aven::WorkspaceUser") }
    it { should have_many(:users).through(:workspace_users).class_name("Aven::User") }
  end

  describe "validations" do
    it { should validate_presence_of(:label) }
    subject { create(:aven_workspace_role) }
    it { should validate_uniqueness_of(:label).scoped_to(:workspace_id) }
  end

  describe "constants and scopes" do
    it "defines predefined roles" do
      expect(described_class::PREDEFINED_ROLES).to include("owner", "admin", "member", "viewer")
    end

    it "predefined? and custom? behave as expected" do
      ws = create(:aven_workspace)
      r1 = create(:aven_workspace_role, workspace: ws, label: "owner")
      r2 = create(:aven_workspace_role, workspace: ws, label: "custom_role")

      expect(r1.predefined?).to be true
      expect(r1.custom?).to be false
      expect(r2.predefined?).to be false
      expect(r2.custom?).to be true
    end
  end
end
