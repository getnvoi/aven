# frozen_string_literal: true

require "test_helper"

class Aven::Auth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Aven.configuration.enable_password_registration = true
  end

  def teardown
    Aven.configuration.enable_password_registration = false
  end

  # Route tests
  test "register route exists" do
    assert_recognizes(
      { controller: "aven/auth/registrations", action: "new" },
      { method: :get, path: "/aven/auth/register" }
    )
  end

  test "register create route exists" do
    assert_recognizes(
      { controller: "aven/auth/registrations", action: "create" },
      { method: :post, path: "/aven/auth/register" }
    )
  end

  # New action tests
  test "new shows registration form" do
    skip "AuthCard component not available"
    get aven.auth_register_path
    assert_response :success
    assert_select "input[name=email]"
    assert_select "input[name=password]"
    assert_select "input[name=password_confirmation]"
  end

  test "new form has submit button with type submit" do
    skip "AuthCard component not available"
    get aven.auth_register_path
    assert_response :success
    assert_select "button[type=submit]", text: /Create account/
  end

  test "new redirects when registration disabled" do
    Aven.configuration.enable_password_registration = false

    get aven.auth_register_path
    assert_response :redirect
    assert_redirected_to aven.auth_login_path
  end

  test "new redirects when already signed in" do
    skip "AuthCard component not available"
    user = create_user_with_workspace
    sign_in_as(user, user.workspaces.first)

    get aven.auth_register_path
    assert_response :redirect
  end

  # Create action tests
  test "create registers user with valid data" do
    assert_difference "Aven::User.count", 1 do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    end

    assert_response :redirect
    assert_equal "Your account has been created successfully.", flash[:notice]
  end

  test "create signs in user after registration" do
    assert_difference "Aven::Session.count", 1 do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    end
  end

  test "create creates workspace for new user" do
    assert_difference "Aven::Workspace.count", 1 do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    end
  end

  test "create rejects mismatched passwords" do
    assert_no_difference "Aven::User.count" do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "differentpassword"
      }
    end

    assert_response :unprocessable_entity
    assert_select "[data-variant=error]" # alert component
  end

  test "create rejects existing email" do
    skip "AuthCard component not available"
    Aven::User.create!(
      email: "existing@example.com",
      auth_tenant: "www.example.com",
      password: "securepassword123"
    )

    assert_no_difference "Aven::User.count" do
      post aven.auth_register_path, params: {
        email: "existing@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects empty email" do
    assert_no_difference "Aven::User.count" do
      post aven.auth_register_path, params: {
        email: "",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects empty password" do
    skip "AuthCard component not available"
    assert_no_difference "Aven::User.count" do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "",
        password_confirmation: ""
      }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects short password" do
    skip "AuthCard component not available"
    Aven.configuration.password_minimum_length = 12

    assert_no_difference "Aven::User.count" do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "short",
        password_confirmation: "short"
      }
    end

    assert_response :unprocessable_entity
  end

  test "create normalizes email to lowercase" do
    post aven.auth_register_path, params: {
      email: "NEWUSER@EXAMPLE.COM",
      password: "securepassword123",
      password_confirmation: "securepassword123"
    }

    assert_response :redirect
    assert Aven::User.exists?(email: "newuser@example.com", auth_tenant: "www.example.com")
  end

  test "create sets auth_tenant from request host" do
    post aven.auth_register_path, params: {
      email: "newuser@example.com",
      password: "securepassword123",
      password_confirmation: "securepassword123"
    }

    user = Aven::User.find_by(email: "newuser@example.com")
    assert_equal "www.example.com", user.auth_tenant
  end

  test "create redirects when registration disabled" do
    Aven.configuration.enable_password_registration = false

    assert_no_difference "Aven::User.count" do
      post aven.auth_register_path, params: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    end

    assert_response :redirect
  end

  private

    def create_user_with_workspace
      user = Aven::User.create!(
        email: "existing@example.com",
        auth_tenant: "www.example.com",
        password: "securepassword123"
      )
      workspace = Aven::Workspace.create!(label: "Test Workspace", created_by: @user)
      Aven::WorkspaceUser.create!(user: user, workspace: workspace)
      user.reload
      user
    end
end
