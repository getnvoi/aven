require "test_helper"

class Aven::WorkspaceUserRoleTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace_user" do
    wur = aven_workspace_user_roles(:one)
    assert_respond_to wur, :workspace_user
  end

  test "belongs to workspace_role" do
    wur = aven_workspace_user_roles(:one)
    assert_respond_to wur, :workspace_role
  end

  # Validations
  test "validates uniqueness of workspace_user_id scoped to workspace_role_id" do
    existing = aven_workspace_user_roles(:one)
    wur = Aven::WorkspaceUserRole.new(
      workspace_user: existing.workspace_user,
      workspace_role: existing.workspace_role
    )

    assert_not wur.valid?
    assert_includes wur.errors[:workspace_user_id], "has already been taken"
  end

  # Delegates and scopes
  test "delegates attributes" do
    workspace = aven_workspaces(:one)
    user = Aven::User.create!(email: "alice@example.com", auth_tenant: "test", password: "password123")
    workspace_user = Aven::WorkspaceUser.create!(workspace: workspace, user: user)
    role = Aven::WorkspaceRole.create!(workspace: workspace, label: "custom_member", description: "Member role")
    wur = Aven::WorkspaceUserRole.create!(workspace_user: workspace_user, workspace_role: role)

    assert_equal workspace, wur.workspace
    assert_equal "custom_member", wur.label
    assert_equal "Member role", wur.description
    assert_equal user, wur.user
    assert_equal "alice@example.com", wur.email
  end

  test "filters by workspace" do
    workspace = aven_workspaces(:one)
    wur = aven_workspace_user_roles(:one)

    assert_includes Aven::WorkspaceUserRole.for_workspace(workspace), wur
  end

  test "filters by role label" do
    workspace = aven_workspaces(:one)
    user = Aven::User.create!(email: "bob@example.com", auth_tenant: "test", password: "password123")
    workspace_user = Aven::WorkspaceUser.create!(workspace: workspace, user: user)
    role = Aven::WorkspaceRole.create!(workspace: workspace, label: "custom_viewer")
    wur = Aven::WorkspaceUserRole.create!(workspace_user: workspace_user, workspace_role: role)

    assert_includes Aven::WorkspaceUserRole.with_role("custom_viewer"), wur
    assert_not_includes Aven::WorkspaceUserRole.with_role("owner"), wur
  end
end
