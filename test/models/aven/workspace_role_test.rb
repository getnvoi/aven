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
require "test_helper"

class Aven::WorkspaceRoleTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace" do
    role = aven_workspace_roles(:one)
    assert_respond_to role, :workspace
  end

  test "has many workspace_user_roles" do
    role = aven_workspace_roles(:one)
    assert_respond_to role, :workspace_user_roles
  end

  test "has many workspace_users through workspace_user_roles" do
    role = aven_workspace_roles(:one)
    assert_respond_to role, :workspace_users
  end

  test "has many users through workspace_users" do
    role = aven_workspace_roles(:one)
    assert_respond_to role, :users
  end

  # Validations
  test "validates presence of label" do
    role = Aven::WorkspaceRole.new(workspace: aven_workspaces(:one), label: nil)
    assert_not role.valid?
    assert_includes role.errors[:label], "can't be blank"
  end

  test "validates uniqueness of label scoped to workspace_id" do
    workspace = aven_workspaces(:one)
    existing_role = aven_workspace_roles(:one)

    role = Aven::WorkspaceRole.new(workspace:, label: existing_role.label)
    assert_not role.valid?
    assert_includes role.errors[:label], "has already been taken"
  end

  # Constants and scopes
  test "defines predefined roles" do
    assert_includes Aven::WorkspaceRole::PREDEFINED_ROLES, "owner"
    assert_includes Aven::WorkspaceRole::PREDEFINED_ROLES, "admin"
    assert_includes Aven::WorkspaceRole::PREDEFINED_ROLES, "member"
    assert_includes Aven::WorkspaceRole::PREDEFINED_ROLES, "viewer"
  end

  test "predefined? and custom? behave as expected" do
    workspace = aven_workspaces(:one)
    owner_role = Aven::WorkspaceRole.create!(workspace:, label: "owner")
    custom_role = Aven::WorkspaceRole.create!(workspace:, label: "custom_role")

    assert owner_role.predefined?
    assert_not owner_role.custom?
    assert_not custom_role.predefined?
    assert custom_role.custom?
  end
end
