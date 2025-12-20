# frozen_string_literal: true

require "test_helper"

class Aven::Auth::PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = Aven::User.create!(
      email: "reset-test@example.com",
      auth_tenant: "www.example.com",
      password: "oldpassword123"
    )
    @workspace = Aven::Workspace.create!(label: "Test Workspace")
    Aven::WorkspaceUser.create!(user: @user, workspace: @workspace)
  end

  # Route tests
  test "password reset new route exists" do
    assert_recognizes(
      { controller: "aven/auth/password_resets", action: "new" },
      { method: :get, path: "/aven/auth/password_reset" }
    )
  end

  test "password reset create route exists" do
    assert_recognizes(
      { controller: "aven/auth/password_resets", action: "create" },
      { method: :post, path: "/aven/auth/password_reset" }
    )
  end

  test "password reset edit route exists" do
    assert_recognizes(
      { controller: "aven/auth/password_resets", action: "edit" },
      { method: :get, path: "/aven/auth/password_reset/edit" }
    )
  end

  test "password reset update route exists" do
    assert_recognizes(
      { controller: "aven/auth/password_resets", action: "update" },
      { method: :patch, path: "/aven/auth/password_reset" }
    )
  end

  # Create action tests
  test "create sends reset email for valid user" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post aven.auth_password_reset_path, params: { email: @user.email }
    end

    assert_redirected_to aven.auth_login_path
    assert_equal "If that email exists, we sent password reset instructions.", flash[:notice]
  end

  test "create does not reveal if email does not exist" do
    post aven.auth_password_reset_path, params: { email: "nonexistent@example.com" }

    assert_redirected_to aven.auth_login_path
    assert_equal "If that email exists, we sent password reset instructions.", flash[:notice]
  end

  # Edit action tests
  test "edit with valid token shows reset form" do
    token = @user.generate_token_for(:password_reset)

    get aven.auth_edit_password_reset_path, params: { token: token }

    assert_response :success
  end

  test "edit with invalid token redirects" do
    get aven.auth_edit_password_reset_path, params: { token: "invalid_token" }

    assert_redirected_to aven.auth_password_reset_path
    assert_equal "Invalid or expired password reset link.", flash[:alert]
  end

  # Update action tests
  test "update with valid token changes password" do
    token = @user.generate_token_for(:password_reset)
    new_password = "newpassword12345"

    patch aven.auth_password_reset_path, params: {
      token: token,
      password: new_password,
      password_confirmation: new_password
    }

    assert_redirected_to aven.auth_login_path
    assert_equal "Your password has been reset. Please sign in.", flash[:notice]

    # Verify password was changed
    @user.reload
    assert @user.authenticate(new_password)
  end

  test "update invalidates all existing sessions" do
    # Create some sessions first
    3.times { @user.sessions.create!(ip_address: "1.1.1.1", user_agent: "Test", last_active_at: Time.current) }
    initial_session_count = @user.sessions.count
    assert initial_session_count > 0

    token = @user.generate_token_for(:password_reset)
    new_password = "newpassword12345"

    patch aven.auth_password_reset_path, params: {
      token: token,
      password: new_password,
      password_confirmation: new_password
    }

    assert_equal 0, @user.reload.sessions.count
  end

  test "update with invalid token redirects" do
    patch aven.auth_password_reset_path, params: {
      token: "invalid_token",
      password: "newpassword12345",
      password_confirmation: "newpassword12345"
    }

    assert_redirected_to aven.auth_password_reset_path
    assert_equal "Invalid or expired password reset link.", flash[:alert]
  end

  test "update with password mismatch re-renders form" do
    token = @user.generate_token_for(:password_reset)
    original_digest = @user.password_digest

    patch aven.auth_password_reset_path, params: {
      token: token,
      password: "newpassword12345",
      password_confirmation: "differentpassword"
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_equal original_digest, @user.password_digest
  end

  test "update with short password re-renders form" do
    token = @user.generate_token_for(:password_reset)
    original_digest = @user.password_digest

    patch aven.auth_password_reset_path, params: {
      token: token,
      password: "short",
      password_confirmation: "short"
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_equal original_digest, @user.password_digest
  end
end
