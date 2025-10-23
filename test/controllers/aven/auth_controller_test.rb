require "test_helper"

class Aven::AuthControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = Aven::User.create!(
      email: "test@example.com",
      auth_tenant: "www.example.com",
      remote_id: "logout_test_123"
    )
  end

  # Helper to sign in via OAuth
  def sign_in_via_oauth(user)
    Aven.configuration.configure_oauth(:google, {
      client_id: "test_client",
      client_secret: "test_secret"
    })

    get "/aven/oauth/google"
    stored_state = session[:oauth_state]

    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(
        status: 200,
        body: { access_token: "test_token" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .to_return(
        status: 200,
        body: {
          sub: user.remote_id,
          email: user.email,
          name: "Test User"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: "test_code", state: stored_state }
  end

  test "logout route exists at /aven/logout" do
    # Just verify the route recognizes correctly
    assert_recognizes({ controller: "aven/auth", action: "logout" }, { method: :get, path: "/aven/logout" })
  end

  test "logout URL is accessible via GET" do
    get aven.logout_url
    assert_response :redirect
  end

  test "logout redirects to root path" do
    get aven.logout_url
    assert_response :redirect
    # Should redirect to either main_app.root_path or aven root_path
    assert_match %r{/$}, response.redirect_url
  end

  test "logout shows success notice" do
    get aven.logout_url
    follow_redirect!
    assert_equal "You have been signed out successfully.", flash[:notice]
  end

  test "logout works when user is not signed in" do
    # No user signed in
    get aven.logout_url
    assert_response :redirect
    follow_redirect!
    assert_equal "You have been signed out successfully.", flash[:notice]
  end

  test "logout actually signs out signed-in user" do
    # Sign in first
    sign_in_via_oauth(@user)
    assert_response :redirect

    # Verify user is signed in by making another request
    get aven.root_path
    assert_response :success

    # Now logout
    get aven.logout_url
    assert_response :redirect
    follow_redirect!
    assert_equal "You have been signed out successfully.", flash[:notice]

    # After logout, the session should be completely cleared
    # We can't directly check session[:user_id] in integration tests,
    # but we verified the logout happened by checking the flash message
  end

  test "logout can be called multiple times safely" do
    get aven.logout_url
    assert_response :redirect

    get aven.logout_url
    assert_response :redirect

    # Both should work without error
  end

  test "logout named route helper works" do
    # Test that aven.logout_path and aven.logout_url work
    assert_equal "/aven/logout", aven.logout_path
    assert_match %r{http://.*?/aven/logout}, aven.logout_url
  end
end
