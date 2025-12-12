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
require "test_helper"

class Aven::WorkspaceUserTest < ActiveSupport::TestCase
  # Associations
  test "belongs to user" do
    workspace_user = aven_workspace_users(:one)
    assert_respond_to workspace_user, :user
  end

  test "belongs to workspace" do
    workspace_user = aven_workspace_users(:one)
    assert_respond_to workspace_user, :workspace
  end

  test "has many workspace_user_roles" do
    workspace_user = aven_workspace_users(:one)
    assert_respond_to workspace_user, :workspace_user_roles
  end

  test "has many workspace_roles through workspace_user_roles" do
    workspace_user = aven_workspace_users(:one)
    assert_respond_to workspace_user, :workspace_roles
  end

  # Validations
  test "validates uniqueness of user_id scoped to workspace_id" do
    existing = aven_workspace_users(:one)
    workspace_user = Aven::WorkspaceUser.new(user: existing.user, workspace: existing.workspace)

    assert_not workspace_user.valid?
    assert_includes workspace_user.errors[:user_id], "has already been taken"
  end

  # Role helpers
  test "returns empty roles initially" do
    workspace = aven_workspaces(:one)
    user = Aven::User.create!(email: "newuser@example.com", auth_tenant: "test")
    workspace_user = Aven::WorkspaceUser.create!(user: user, workspace: workspace)

    assert_equal [], workspace_user.roles
  end

  test "adds and lists roles" do
    workspace = aven_workspaces(:one)
    user = Aven::User.create!(email: "tester@example.com", auth_tenant: "test")
    workspace_user = Aven::WorkspaceUser.create!(user: user, workspace: workspace)

    workspace_user.add_role("owner")
    workspace_user.add_role("admin")

    assert_equal [ "owner", "admin" ].sort, workspace_user.roles.sort
    assert workspace_user.has_role?("owner")
  end

  test "removes roles" do
    workspace = aven_workspaces(:one)
    user = Aven::User.create!(email: "tester2@example.com", auth_tenant: "test")
    workspace_user = Aven::WorkspaceUser.create!(user: user, workspace: workspace)

    workspace_user.add_role("member")
    assert_includes workspace_user.roles, "member"

    workspace_user.remove_role("member")
    assert_not_includes workspace_user.roles, "member"
  end
end
