# frozen_string_literal: true

require "test_helper"

class Aven::Auth::MagicLinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = Aven::User.create!(
      email: "magic@example.com",
      auth_tenant: "www.example.com"
    )
    @workspace = Aven::Workspace.create!(label: "Test Workspace", created_by: @user)
    Aven::WorkspaceUser.create!(user: @user, workspace: @workspace)
  end

  # Route tests
  test "magic link new route exists" do
    assert_recognizes(
      { controller: "aven/auth/magic_links", action: "new" },
      { method: :get, path: "/aven/auth/magic_link" }
    )
  end

  test "magic link create route exists" do
    assert_recognizes(
      { controller: "aven/auth/magic_links", action: "create" },
      { method: :post, path: "/aven/auth/magic_link" }
    )
  end

  test "magic link verify route exists" do
    assert_recognizes(
      { controller: "aven/auth/magic_links", action: "verify" },
      { method: :get, path: "/aven/auth/magic_link/verify" }
    )
  end

  test "magic link consume route exists" do
    assert_recognizes(
      { controller: "aven/auth/magic_links", action: "consume" },
      { method: :post, path: "/aven/auth/magic_link/consume" }
    )
  end

  # Create action tests
  test "create sends magic link email for valid user" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post aven.auth_magic_link_path, params: { email: @user.email }
    end

    assert_redirected_to aven.auth_verify_magic_link_path
    assert_equal "Check your email for a sign-in code.", flash[:notice]
  end

  test "create creates magic link for valid user" do
    assert_difference "Aven::MagicLink.count", 1 do
      post aven.auth_magic_link_path, params: { email: @user.email }
    end

    magic_link = Aven::MagicLink.last
    assert_equal @user, magic_link.user
    assert magic_link.sign_in?
  end

  test "create does not reveal if email does not exist" do
    post aven.auth_magic_link_path, params: { email: "nonexistent@example.com" }

    assert_redirected_to aven.auth_verify_magic_link_path
    assert_equal "If that email exists, we sent a sign-in code.", flash[:notice]
  end

  test "create does not create magic link for nonexistent email" do
    assert_no_difference "Aven::MagicLink.count" do
      post aven.auth_magic_link_path, params: { email: "nonexistent@example.com" }
    end
  end

  test "create normalizes email to lowercase" do
    post aven.auth_magic_link_path, params: { email: "MAGIC@EXAMPLE.COM" }
    assert_redirected_to aven.auth_verify_magic_link_path
  end

  # Consume action tests
  test "consume signs in user with valid code" do
    magic_link = @user.magic_links.create!(purpose: :sign_in)

    post aven.auth_consume_magic_link_path, params: { code: magic_link.code }

    assert_response :redirect
    assert_equal "You have been signed in successfully.", flash[:notice]
  end

  test "consume destroys magic link after use" do
    magic_link = @user.magic_links.create!(purpose: :sign_in)
    code = magic_link.code

    assert_difference "Aven::MagicLink.count", -1 do
      post aven.auth_consume_magic_link_path, params: { code: code }
    end
  end

  test "consume creates session record" do
    magic_link = @user.magic_links.create!(purpose: :sign_in)

    assert_difference "Aven::Session.count", 1 do
      post aven.auth_consume_magic_link_path, params: { code: magic_link.code }
    end

    session = Aven::Session.last
    assert_equal @user, session.user
  end

  test "consume normalizes code input" do
    magic_link = @user.magic_links.create!(purpose: :sign_in)

    # Use lowercase version of code
    post aven.auth_consume_magic_link_path, params: { code: magic_link.code.downcase }

    assert_response :redirect
    assert_equal "You have been signed in successfully.", flash[:notice]
  end

  test "consume creates default workspace if user has none" do
    user_without_workspace = Aven::User.create!(
      email: "nowp@example.com",
      auth_tenant: "www.example.com"
    )
    magic_link = user_without_workspace.magic_links.create!(purpose: :sign_in)

    # This test expects workspace creation to happen automatically in the controller
    assert_difference "Aven::Workspace.count", 1 do
      post aven.auth_consume_magic_link_path, params: { code: magic_link.code }
    end
  end

  # Redirect behavior when already signed in
  test "new redirects when already signed in" do
    # Sign in first via magic link
    magic_link = @user.magic_links.create!(purpose: :sign_in)
    post aven.auth_consume_magic_link_path, params: { code: magic_link.code }
    assert_response :redirect
    follow_redirect!

    # Now try to access new - should redirect
    get aven.auth_magic_link_path
    assert_response :redirect
  end
end
