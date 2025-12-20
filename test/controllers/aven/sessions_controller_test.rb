# frozen_string_literal: true

require "test_helper"

class Aven::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = Aven::User.create!(
      email: "sessions-test@example.com",
      auth_tenant: "www.example.com"
    )
    @workspace = Aven::Workspace.create!(label: "Test Workspace", created_by: @user)
    Aven::WorkspaceUser.create!(user: @user, workspace: @workspace)
  end

  # Route tests
  test "sessions index route exists" do
    assert_recognizes(
      { controller: "aven/sessions", action: "index" },
      { method: :get, path: "/aven/sessions" }
    )
  end

  test "sessions destroy route exists" do
    assert_recognizes(
      { controller: "aven/sessions", action: "destroy", id: "1" },
      { method: :delete, path: "/aven/sessions/1" }
    )
  end

  test "sessions revoke_all route exists" do
    assert_recognizes(
      { controller: "aven/sessions", action: "revoke_all" },
      { method: :delete, path: "/aven/sessions/revoke_all" }
    )
  end

  # Authentication tests
  test "index requires authentication" do
    get "/aven/sessions"
    assert_response :redirect
  end

  test "destroy requires authentication" do
    session = @user.sessions.create!(
      ip_address: "1.2.3.4",
      user_agent: "Test",
      last_active_at: Time.current
    )
    delete "/aven/sessions/#{session.id}"
    assert_response :redirect
  end

  test "revoke_all requires authentication" do
    delete "/aven/sessions/revoke_all"
    assert_response :redirect
  end

  # Index tests
  test "index returns json with sessions list" do
    sign_in_as(@user, @workspace)
    get "/aven/sessions", as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.first["id"].present?
  end

  test "index returns sessions with current indicator" do
    sign_in_as(@user, @workspace)
    current_session = @user.sessions.last

    get "/aven/sessions", as: :json
    assert_response :success

    json = JSON.parse(response.body)
    current = json.find { |s| s["id"] == current_session.id }
    assert current["current"]
  end

  # Destroy tests
  test "destroy revokes another session" do
    sign_in_as(@user, @workspace)
    current_session = @user.sessions.last

    other_session = @user.sessions.create!(
      ip_address: "5.6.7.8",
      user_agent: "Other Browser",
      last_active_at: 1.hour.ago
    )

    assert_difference "Aven::Session.count", -1 do
      delete "/aven/sessions/#{other_session.id}"
    end

    assert_redirected_to aven.sessions_path
    assert_equal "Session revoked successfully.", flash[:notice]

    # Current session should still exist
    assert Aven::Session.exists?(current_session.id)
  end

  test "destroy current session signs out" do
    sign_in_as(@user, @workspace)
    current_session = @user.sessions.last

    delete "/aven/sessions/#{current_session.id}"

    assert_response :redirect
    assert_equal "You have been signed out.", flash[:notice]
  end

  test "destroy cannot revoke another user's session" do
    sign_in_as(@user, @workspace)

    other_user = Aven::User.create!(
      email: "other@example.com",
      auth_tenant: "www.example.com"
    )
    other_session = other_user.sessions.create!(
      ip_address: "9.9.9.9",
      user_agent: "Other",
      last_active_at: Time.current
    )

    # Other user's session should not be affected
    assert_no_difference "Aven::Session.count" do
      delete "/aven/sessions/#{other_session.id}"
    end

    # Returns 404 because the session wasn't found in current_user.sessions
    assert_response :not_found
  end

  # Revoke all tests
  test "revoke_all destroys all other sessions" do
    sign_in_as(@user, @workspace)
    current_session = @user.sessions.last

    # Create additional sessions
    3.times do |i|
      @user.sessions.create!(
        ip_address: "1.1.1.#{i}",
        user_agent: "Browser #{i}",
        last_active_at: i.hours.ago
      )
    end

    assert_equal 4, @user.sessions.count

    delete "/aven/sessions/revoke_all"

    assert_redirected_to aven.sessions_path
    assert_equal "All other sessions have been revoked.", flash[:notice]

    # Only current session should remain
    assert_equal 1, @user.sessions.reload.count
    assert Aven::Session.exists?(current_session.id)
  end

  test "revoke_all does nothing if only current session exists" do
    sign_in_as(@user, @workspace)

    assert_equal 1, @user.sessions.count

    assert_no_difference "Aven::Session.count" do
      delete "/aven/sessions/revoke_all"
    end

    assert_redirected_to aven.sessions_path
  end
end
