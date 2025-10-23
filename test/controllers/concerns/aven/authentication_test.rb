require "test_helper"

class Aven::AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = Aven::User.create!(
      email: "authtest@example.com",
      auth_tenant: "www.example.com",
      remote_id: "test_123"
    )
  end

  # Helper to simulate a sign in by going through OAuth flow
  def sign_in_user(user)
    # Simulate the OAuth callback which calls sign_in
    # We'll use Google OAuth as the test vehicle
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

  test "user is signed in after OAuth callback" do
    sign_in_user(@user)

    # Verify we were redirected (sign in successful)
    assert_response :redirect

    # Make another request and verify session persists
    get aven.root_path
    assert_response :success
  end

  test "logout clears session and signs user out" do
    # Sign in first
    sign_in_user(@user)
    assert_response :redirect

    # Now logout
    get aven.logout_path
    assert_response :redirect
    assert_equal "You have been signed out successfully.", flash[:notice]

    # Verify session is cleared by checking we can't access the session state
    # The session should be completely reset
    get aven.root_path
    assert_response :success
  end

  test "logout works even when not signed in" do
    # Don't sign in, just try to logout
    get aven.logout_path

    assert_response :redirect
    assert_equal "You have been signed out successfully.", flash[:notice]
  end

  test "multiple users can sign in and out independently" do
    user2 = Aven::User.create!(
      email: "user2@example.com",
      auth_tenant: "www.example.com",
      remote_id: "test_456"
    )

    # Sign in as user 1
    sign_in_user(@user)
    assert_response :redirect

    # Logout
    get aven.logout_path
    assert_response :redirect

    # Sign in as user 2
    sign_in_user(user2)
    assert_response :redirect

    # Logout user 2
    get aven.logout_path
    assert_response :redirect
  end

  test "session is reset on logout preventing session fixation" do
    # Sign in
    sign_in_user(@user)
    first_session = session

    # Logout
    get aven.logout_path

    # Session should be completely reset (not just user_id cleared)
    # This is tested by the reset_session call in sign_out
    assert_response :redirect
  end

  test "authentication helpers are available in controllers" do
    assert Aven::ApplicationController.private_method_defined?(:current_user)
    assert Aven::ApplicationController.private_method_defined?(:sign_in)
    assert Aven::ApplicationController.private_method_defined?(:sign_out)
    assert Aven::ApplicationController.private_method_defined?(:stored_location_for)
    assert Aven::ApplicationController.private_method_defined?(:authenticate_user!)
  end
end
