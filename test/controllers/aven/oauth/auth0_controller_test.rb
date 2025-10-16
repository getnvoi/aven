require "test_helper"

class Aven::Oauth::Auth0ControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Configure OAuth for testing
    Aven.configuration.configure_oauth(:auth0, {
      domain: "test-tenant.auth0.com",
      client_id: "test_auth0_client_id",
      client_secret: "test_auth0_client_secret"
    })
  end

  test "redirects to Auth0 OAuth authorization URL" do
    get "/aven/oauth/auth0"

    assert_response :redirect
    assert_includes response.location, "https://test-tenant.auth0.com/authorize"
    assert_includes response.location, "client_id=test_auth0_client_id"
    assert_includes response.location, "scope=openid+email+profile"
    assert_includes response.location, "response_type=code"
  end

  test "includes audience parameter when configured" do
    Aven.configuration.configure_oauth(:auth0, {
      domain: "test-tenant.auth0.com",
      client_id: "test_auth0_client_id",
      client_secret: "test_auth0_client_secret",
      audience: "https://api.example.com"
    })

    get "/aven/oauth/auth0"

    assert_response :redirect
    assert_includes response.location, "audience=https%3A%2F%2Fapi.example.com"
  end

  test "uses custom scope when configured" do
    Aven.configuration.configure_oauth(:auth0, {
      domain: "test-tenant.auth0.com",
      client_id: "test_auth0_client_id",
      client_secret: "test_auth0_client_secret",
      scope: "openid email profile read:users"
    })

    get "/aven/oauth/auth0"

    assert_response :redirect
    assert_includes response.location, "scope=openid+email+profile+read%3Ausers"
  end

  test "stores state in session" do
    get "/aven/oauth/auth0"
    assert session[:oauth_state].present?
  end

  test "creates a new user if not exists" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Mock Auth0 token exchange
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .with(
        body: {
          grant_type: "authorization_code",
          client_id: "test_auth0_client_id",
          client_secret: "test_auth0_client_secret",
          code: auth_code,
          redirect_uri: "http://www.example.com/aven/oauth/auth0/callback"
        }
      )
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Auth0 user info
    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .with(headers: { "Authorization" => "Bearer auth0_test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "auth0|123456789",
          email: "auth0user@example.com",
          name: "Auth0 Test User",
          picture: "https://s.gravatar.com/avatar/test.png"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Aven::User.count", 1 do
      get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }
    end

    user = Aven::User.last
    assert_equal "auth0user@example.com", user.email
    assert_equal "auth0|123456789", user.remote_id
    assert_equal "auth0_test_token", user.access_token
  end

  test "signs in existing user by email" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Create existing user with same email but no remote_id
    existing_user = Aven::User.create!(
      email: "auth0user@example.com",
      auth_tenant: "www.example.com",
      password: SecureRandom.hex(16)
    )

    # Mock Auth0 token exchange
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .with(
        body: {
          grant_type: "authorization_code",
          client_id: "test_auth0_client_id",
          client_secret: "test_auth0_client_secret",
          code: auth_code,
          redirect_uri: "http://www.example.com/aven/oauth/auth0/callback"
        }
      )
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Auth0 user info
    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .with(headers: { "Authorization" => "Bearer auth0_test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "auth0|123456789",
          email: "auth0user@example.com",
          name: "Auth0 Test User",
          picture: "https://s.gravatar.com/avatar/test.png"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_no_difference "Aven::User.count" do
      get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }
    end

    existing_user.reload
    assert_equal "auth0|123456789", existing_user.remote_id
    assert_equal "auth0_test_token", existing_user.access_token
    assert_response :redirect
  end

  test "signs in existing user by remote_id" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Create existing user with same remote_id
    existing_user = Aven::User.create!(
      email: "auth0user@example.com",
      remote_id: "auth0|123456789",
      auth_tenant: "www.example.com",
      password: SecureRandom.hex(16)
    )

    # Mock Auth0 token exchange
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .with(
        body: {
          grant_type: "authorization_code",
          client_id: "test_auth0_client_id",
          client_secret: "test_auth0_client_secret",
          code: auth_code,
          redirect_uri: "http://www.example.com/aven/oauth/auth0/callback"
        }
      )
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Auth0 user info
    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .with(headers: { "Authorization" => "Bearer auth0_test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "auth0|123456789",
          email: "auth0user@example.com",
          name: "Auth0 Test User",
          picture: "https://s.gravatar.com/avatar/test.png"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_no_difference "Aven::User.count" do
      get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }
    end

    existing_user.reload
    assert_equal "auth0_test_token", existing_user.access_token
    assert_response :redirect
  end

  test "uses nickname as name fallback when name is missing" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Mock Auth0 token exchange
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .with(
        body: {
          grant_type: "authorization_code",
          client_id: "test_auth0_client_id",
          client_secret: "test_auth0_client_secret",
          code: auth_code,
          redirect_uri: "http://www.example.com/aven/oauth/auth0/callback"
        }
      )
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .with(headers: { "Authorization" => "Bearer auth0_test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "auth0|123456789",
          email: "auth0user@example.com",
          nickname: "auth0_user",
          picture: "https://s.gravatar.com/avatar/test.png"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Aven::User.count", 1 do
      get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }
    end

    user = Aven::User.last
    assert_equal "auth0user@example.com", user.email
  end

  test "renders error page with invalid state parameter" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"

    get "/aven/oauth/auth0/callback", params: { code: auth_code, state: "wrong_state" }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Invalid state parameter"
  end

  test "handles token exchange failure" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Mock failed token exchange
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .to_return(
        status: 400,
        body: { error: "invalid_grant", error_description: "Invalid authorization code" }.to_json
      )

    get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "OAuth request failed"
  end

  test "handles user info fetch failure" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Mock successful token exchange
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock failed user info fetch
    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .to_return(
        status: 401,
        body: { error: "invalid_token", error_description: "Unauthorized" }.to_json
      )

    get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "OAuth request failed"
  end

  test "handles invalid email format" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Mock successful OAuth responses but with invalid email
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .to_return(
        status: 200,
        body: {
          sub: "auth0|123456789",
          email: "invalid-email",
          name: "Auth0 Test User",
          picture: "https://s.gravatar.com/avatar/test.png"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Email is invalid"
  end

  test "handles missing email" do
    auth_code = "test_auth0_auth_code"

    # Initiate OAuth flow to set up session state
    get "/aven/oauth/auth0"
    stored_state = session[:oauth_state]

    # Mock successful OAuth responses but with missing email
    stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
      .to_return(
        status: 200,
        body: {
          access_token: "auth0_test_token",
          token_type: "Bearer",
          expires_in: 86400
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://test-tenant.auth0.com/userinfo")
      .to_return(
        status: 200,
        body: {
          sub: "auth0|123456789",
          email: nil,
          name: "Auth0 Test User",
          picture: "https://s.gravatar.com/avatar/test.png"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/auth0/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Email can&#39;t be blank"
  end

  test "raises configuration error when Auth0 is not configured" do
    Aven.configuration.oauth_providers = {}

    assert_raises RuntimeError, "Auth0 OAuth not configured" do
      get "/aven/oauth/auth0"
    end
  end

  test "raises configuration error when Auth0 domain is not configured" do
    Aven.configuration.configure_oauth(:auth0, {
      client_id: "test_auth0_client_id",
      client_secret: "test_auth0_client_secret"
    })

    assert_raises RuntimeError, "Auth0 domain not configured" do
      get "/aven/oauth/auth0"
    end
  end
end
