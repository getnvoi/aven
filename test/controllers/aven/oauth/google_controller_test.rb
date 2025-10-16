require "test_helper"

class Aven::Oauth::GoogleControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Configure OAuth for testing
    Aven.configuration.configure_oauth(:google, {
      client_id: "test_client_id",
      client_secret: "test_client_secret"
    })
  end

  # GET /aven/oauth/google tests

  test "redirects to Google OAuth authorization URL" do
    get "/aven/oauth/google"

    assert_response :redirect
    assert_includes response.location, "https://accounts.google.com/o/oauth2/v2/auth"
    assert_includes response.location, "client_id=test_client_id"
    assert_includes response.location, "scope=openid+email+profile"
    assert_includes response.location, "response_type=code"
  end

  test "stores state in session" do
    get "/aven/oauth/google"
    assert_not_nil session[:oauth_state]
  end

  # GET /aven/oauth/google/callback tests

  # Valid OAuth flow tests

  test "creates a new user if not exists" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    stored_state = session[:oauth_state]
    auth_code = "test_auth_code"

    # Mock Google token exchange
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .with(
        body: {
          code: auth_code,
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          redirect_uri: "http://www.example.com/aven/oauth/google/callback",
          grant_type: "authorization_code"
        }
      )
      .to_return(
        status: 200,
        body: { access_token: "test_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Google user info
    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .with(headers: { "Authorization" => "Bearer test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "google_123",
          email: "test@example.com",
          name: "Test User",
          picture: "https://example.com/picture.jpg"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Aven::User.count", 1 do
      get "/aven/oauth/google/callback", params: { code: auth_code, state: stored_state }
    end

    user = Aven::User.last
    assert_equal "test@example.com", user.email
    assert_equal "google_123", user.remote_id
  end

  test "signs in existing user" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    stored_state = session[:oauth_state]
    auth_code = "test_auth_code"

    # Create existing user
    existing_user = Aven::User.create!(
      email: "test@example.com",
      remote_id: "google_123",
      auth_tenant: "www.example.com",
      password: SecureRandom.hex(16)
    )

    # Mock Google token exchange
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .with(
        body: {
          code: auth_code,
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          redirect_uri: "http://www.example.com/aven/oauth/google/callback",
          grant_type: "authorization_code"
        }
      )
      .to_return(
        status: 200,
        body: { access_token: "test_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Google user info
    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .with(headers: { "Authorization" => "Bearer test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "google_123",
          email: "test@example.com",
          name: "Test User",
          picture: "https://example.com/picture.jpg"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_no_difference "Aven::User.count" do
      get "/aven/oauth/google/callback", params: { code: auth_code, state: stored_state }
    end

    assert_response :redirect
  end

  test "updates access token for existing user" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    stored_state = session[:oauth_state]
    auth_code = "test_auth_code"

    existing_user = Aven::User.create!(
      email: "test@example.com",
      remote_id: "google_123",
      auth_tenant: "www.example.com",
      password: SecureRandom.hex(16)
    )

    # Mock Google token exchange
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .with(
        body: {
          code: auth_code,
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          redirect_uri: "http://www.example.com/aven/oauth/google/callback",
          grant_type: "authorization_code"
        }
      )
      .to_return(
        status: 200,
        body: { access_token: "test_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Google user info
    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .with(headers: { "Authorization" => "Bearer test_token" })
      .to_return(
        status: 200,
        body: {
          sub: "google_123",
          email: "test@example.com",
          name: "Test User",
          picture: "https://example.com/picture.jpg"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: auth_code, state: stored_state }

    existing_user.reload
    assert_equal "test_token", existing_user.access_token
  end

  # Invalid state parameter tests

  test "renders error page with invalid state parameter" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    auth_code = "test_auth_code"

    get "/aven/oauth/google/callback", params: { code: auth_code, state: "wrong_state" }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Invalid state parameter"
  end

  # OAuth provider error tests

  test "handles token exchange failure" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    stored_state = session[:oauth_state]
    auth_code = "test_auth_code"

    # Mock failed token exchange
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(status: 400, body: { error: "invalid_grant" }.to_json)

    get "/aven/oauth/google/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "OAuth request failed"
  end

  test "handles user info fetch failure" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    stored_state = session[:oauth_state]
    auth_code = "test_auth_code"

    # Mock successful token exchange
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(
        status: 200,
        body: { access_token: "test_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock failed user info fetch
    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .to_return(status: 401, body: { error: "invalid_token" }.to_json)

    get "/aven/oauth/google/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "OAuth request failed"
  end

  # User save failure tests

  test "handles missing email" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/google"
    stored_state = session[:oauth_state]
    auth_code = "test_auth_code"

    # Mock successful OAuth responses but with missing email
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(
        status: 200,
        body: { access_token: "test_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .to_return(
        status: 200,
        body: {
          sub: "google_123",
          email: nil,  # Missing email
          name: "Test User",
          picture: "https://example.com/picture.jpg"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: auth_code, state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Email can&#39;t be blank"
  end
end
