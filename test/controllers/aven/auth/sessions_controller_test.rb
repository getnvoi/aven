# frozen_string_literal: true

require "test_helper"

class Aven::Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = Aven::User.create!(
      email: "password-test@example.com",
      auth_tenant: "www.example.com",
      password: "securepassword123"
    )
    @workspace = Aven::Workspace.create!(label: "Test Workspace")
    Aven::WorkspaceUser.create!(user: @user, workspace: @workspace)
  end

  # Route tests
  test "login route exists" do
    assert_recognizes(
      { controller: "aven/auth/sessions", action: "new" },
      { method: :get, path: "/aven/auth/login" }
    )
  end

  test "login create route exists" do
    assert_recognizes(
      { controller: "aven/auth/sessions", action: "create" },
      { method: :post, path: "/aven/auth/login" }
    )
  end

  # Create action tests
  test "create signs in user with valid credentials" do
    post aven.auth_login_path, params: {
      email: @user.email,
      password: "securepassword123"
    }

    assert_response :redirect
    assert_equal "You have been signed in successfully.", flash[:notice]
  end

  test "create creates session record for valid login" do
    assert_difference "Aven::Session.count", 1 do
      post aven.auth_login_path, params: {
        email: @user.email,
        password: "securepassword123"
      }
    end
  end

  test "create rejects invalid password" do
    assert_no_difference "Aven::Session.count" do
      post aven.auth_login_path, params: {
        email: @user.email,
        password: "wrongpassword"
      }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects non-existent user" do
    assert_no_difference "Aven::Session.count" do
      post aven.auth_login_path, params: {
        email: "nonexistent@example.com",
        password: "anypassword"
      }
    end

    assert_response :unprocessable_entity
  end

  test "create normalizes email to lowercase" do
    post aven.auth_login_path, params: {
      email: "PASSWORD-TEST@EXAMPLE.COM",
      password: "securepassword123"
    }

    assert_response :redirect
    assert_equal "You have been signed in successfully.", flash[:notice]
  end

  test "create rejects user without password set" do
    user_no_password = Aven::User.create!(
      email: "nopass@example.com",
      auth_tenant: "www.example.com"
    )

    assert_no_difference "Aven::Session.count" do
      post aven.auth_login_path, params: {
        email: user_no_password.email,
        password: "anypassword"
      }
    end

    assert_response :unprocessable_entity
  end

  # Redirect tests
  test "new redirects when already signed in" do
    sign_in_as(@user, @workspace)

    get aven.auth_login_path
    assert_response :redirect
  end
end
