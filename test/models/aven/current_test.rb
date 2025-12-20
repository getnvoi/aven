# frozen_string_literal: true

require "test_helper"

class Aven::CurrentTest < ActiveSupport::TestCase
  setup do
    Aven::Current.reset
  end

  teardown do
    Aven::Current.reset
  end

  # Attributes
  test "has session attribute" do
    assert_respond_to Aven::Current, :session
    assert_respond_to Aven::Current, :session=
  end

  test "has workspace attribute" do
    assert_respond_to Aven::Current, :workspace
    assert_respond_to Aven::Current, :workspace=
  end

  test "has user_agent attribute" do
    assert_respond_to Aven::Current, :user_agent
    assert_respond_to Aven::Current, :user_agent=
  end

  test "has ip_address attribute" do
    assert_respond_to Aven::Current, :ip_address
    assert_respond_to Aven::Current, :ip_address=
  end

  test "has request_id attribute" do
    assert_respond_to Aven::Current, :request_id
    assert_respond_to Aven::Current, :request_id=
  end

  # User delegation
  test "delegates user to session" do
    user = aven_users(:one)
    session = aven_sessions(:one)

    Aven::Current.session = session

    assert_equal user, Aven::Current.user
  end

  test "user returns nil when session is nil" do
    Aven::Current.session = nil

    assert_nil Aven::Current.user
  end

  # Auto workspace resolution
  test "auto-resolves workspace when user has exactly one workspace" do
    user = aven_users(:one)

    # Ensure user has exactly one workspace
    user.workspaces.destroy_all
    workspace = aven_workspaces(:one)
    Aven::WorkspaceUser.create!(user: user, workspace: workspace)
    user.reload

    session = user.sessions.create!(ip_address: "1.2.3.4", user_agent: "test")

    Aven::Current.session = session

    assert_equal workspace, Aven::Current.workspace
  end

  test "does not auto-resolve workspace when user has multiple workspaces" do
    user = aven_users(:one)

    # Ensure user has multiple workspaces
    workspace1 = aven_workspaces(:one)
    workspace2 = Aven::Workspace.create!(label: "Second Workspace", created_by: user)
    Aven::WorkspaceUser.find_or_create_by!(user: user, workspace: workspace1)
    Aven::WorkspaceUser.find_or_create_by!(user: user, workspace: workspace2)
    user.reload

    session = user.sessions.create!(ip_address: "1.2.3.4", user_agent: "test")

    # Pre-set workspace to nil
    Aven::Current.workspace = nil
    Aven::Current.session = session

    # Should NOT auto-resolve when multiple workspaces
    assert_nil Aven::Current.workspace
  end

  test "does not override existing workspace when setting session" do
    user = aven_users(:one)
    workspace = aven_workspaces(:one)
    Aven::WorkspaceUser.find_or_create_by!(user: user, workspace: workspace)
    user.reload

    session = user.sessions.create!(ip_address: "1.2.3.4", user_agent: "test")

    # Pre-set workspace
    Aven::Current.workspace = workspace

    # Setting session should not change workspace
    Aven::Current.session = session

    assert_equal workspace, Aven::Current.workspace
  end

  # with_workspace helper
  test "with_workspace executes block with workspace context" do
    workspace = aven_workspaces(:one)
    captured_workspace = nil

    Aven::Current.with_workspace(workspace) do
      captured_workspace = Aven::Current.workspace
    end

    assert_equal workspace, captured_workspace
  end

  test "with_workspace restores previous workspace after block" do
    original_workspace = aven_workspaces(:one)
    user = aven_users(:one)
    other_workspace = Aven::Workspace.create!(label: "Other", created_by: user)

    Aven::Current.workspace = original_workspace

    Aven::Current.with_workspace(other_workspace) do
      assert_equal other_workspace, Aven::Current.workspace
    end

    assert_equal original_workspace, Aven::Current.workspace
  end

  test "without_workspace executes block without workspace" do
    workspace = aven_workspaces(:one)
    Aven::Current.workspace = workspace

    Aven::Current.without_workspace do
      assert_nil Aven::Current.workspace
    end

    assert_equal workspace, Aven::Current.workspace
  end

  # authenticated? helper
  test "authenticated? returns true when session and user present" do
    session = aven_sessions(:one)
    Aven::Current.session = session

    assert Aven::Current.authenticated?
  end

  test "authenticated? returns false when session is nil" do
    Aven::Current.session = nil

    assert_not Aven::Current.authenticated?
  end

  test "authenticated? returns false when session has no user" do
    # Create a session mock without user
    session = Aven::Session.new(ip_address: "1.2.3.4", user_agent: "test")
    # Don't save it - user_id is nil

    Aven::Current.session = session

    assert_not Aven::Current.authenticated?
  end

  # workspace? helper
  test "workspace? returns true when workspace is set" do
    Aven::Current.workspace = aven_workspaces(:one)

    assert Aven::Current.workspace?
  end

  test "workspace? returns false when workspace is nil" do
    Aven::Current.workspace = nil

    assert_not Aven::Current.workspace?
  end

  # Reset behavior
  test "reset clears all attributes" do
    Aven::Current.session = aven_sessions(:one)
    Aven::Current.workspace = aven_workspaces(:one)
    Aven::Current.user_agent = "Test Agent"
    Aven::Current.ip_address = "1.2.3.4"
    Aven::Current.request_id = "abc123"

    Aven::Current.reset

    assert_nil Aven::Current.session
    assert_nil Aven::Current.workspace
    assert_nil Aven::Current.user_agent
    assert_nil Aven::Current.ip_address
    assert_nil Aven::Current.request_id
  end

  # Request metadata
  test "stores request metadata" do
    Aven::Current.user_agent = "Mozilla/5.0"
    Aven::Current.ip_address = "192.168.1.1"
    Aven::Current.request_id = "req-123"

    assert_equal "Mozilla/5.0", Aven::Current.user_agent
    assert_equal "192.168.1.1", Aven::Current.ip_address
    assert_equal "req-123", Aven::Current.request_id
  end
end
