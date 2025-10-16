require "test_helper"

class Aven::Oauth::GithubControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Configure OAuth for testing
    Aven.configuration.configure_oauth(:github, {
      client_id: "test_github_client_id",
      client_secret: "test_github_client_secret"
    })
  end

  test "redirects to GitHub OAuth authorization URL" do
    get "/aven/oauth/github"

    assert_response :redirect
    assert_includes response.location, "https://github.com/login/oauth/authorize"
    assert_includes response.location, "client_id=test_github_client_id"
    assert_includes response.location, "scope=user%3Aemail"
  end

  test "uses custom scope when configured" do
    Aven.configuration.configure_oauth(:github, {
      client_id: "test_github_client_id",
      client_secret: "test_github_client_secret",
      scope: "user,user:email,repo,workflow"
    })

    get "/aven/oauth/github"

    assert_response :redirect
    assert_includes response.location, "scope=user%2Cuser%3Aemail%2Crepo%2Cworkflow"
  end

  test "stores state in session" do
    get "/aven/oauth/github"
    assert_not_nil session[:oauth_state]
  end

  test "creates a new user if not exists" do
    # Initiate OAuth flow to set up session state
    get "/aven/oauth/github"
    stored_state = session[:oauth_state]

    # Mock GitHub token exchange
    stub_request(:post, "https://github.com/login/oauth/access_token")
      .with(
        body: {
          client_id: "test_github_client_id",
          client_secret: "test_github_client_secret",
          code: "test_github_auth_code",
          redirect_uri: "http://www.example.com/aven/oauth/github/callback"
        }
      )
      .to_return(
        status: 200,
        body: { access_token: "github_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock GitHub user info
    stub_request(:get, "https://api.github.com/user")
      .with(headers: { "Authorization" => "Bearer github_token" })
      .to_return(
        status: 200,
        body: {
          id: 789456,
          email: "github@example.com",
          name: "GitHub User",
          avatar_url: "https://github.com/avatar.jpg",
          login: "githubuser"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Aven::User.count", 1 do
      get "/aven/oauth/github/callback", params: { code: "test_github_auth_code", state: stored_state }
    end

    user = Aven::User.last
    assert_equal "github@example.com", user.email
    assert_equal "789456", user.remote_id
  end

  test "signs in existing user by email" do
    # Create existing user with same email but no remote_id
    existing_user = Aven::User.create!(
      email: "github@example.com",
      auth_tenant: "www.example.com",
      password: SecureRandom.hex(16)
    )

    # Initiate OAuth flow
    get "/aven/oauth/github"
    stored_state = session[:oauth_state]

    # Mock GitHub responses
    stub_request(:post, "https://github.com/login/oauth/access_token")
      .to_return(
        status: 200,
        body: { access_token: "github_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://api.github.com/user")
      .with(headers: { "Authorization" => "Bearer github_token" })
      .to_return(
        status: 200,
        body: {
          id: 789456,
          email: "github@example.com",
          name: "GitHub User",
          avatar_url: "https://github.com/avatar.jpg",
          login: "githubuser"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_no_difference "Aven::User.count" do
      get "/aven/oauth/github/callback", params: { code: "test_github_auth_code", state: stored_state }
    end

    existing_user.reload
    assert_equal "789456", existing_user.remote_id
    assert_equal "github_token", existing_user.access_token
    assert_response :redirect
  end

  test "handles users without public email" do
    # Initiate OAuth flow
    get "/aven/oauth/github"
    stored_state = session[:oauth_state]

    # Mock token exchange
    stub_request(:post, "https://github.com/login/oauth/access_token")
      .to_return(
        status: 200,
        body: { access_token: "github_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock user info without email
    stub_request(:get, "https://api.github.com/user")
      .with(headers: { "Authorization" => "Bearer github_token" })
      .to_return(
        status: 200,
        body: {
          id: 789456,
          email: nil,  # No public email
          name: "GitHub User",
          avatar_url: "https://github.com/avatar.jpg",
          login: "githubuser"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock emails endpoint
    stub_request(:get, "https://api.github.com/user/emails")
      .with(headers: { "Authorization" => "Bearer github_token" })
      .to_return(
        status: 200,
        body: [
          { email: "private@example.com", primary: true, verified: true }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Aven::User.count", 1 do
      get "/aven/oauth/github/callback", params: { code: "test_github_auth_code", state: stored_state }
    end

    user = Aven::User.last
    assert_equal "private@example.com", user.email
    assert_equal "789456", user.remote_id
  end

  test "renders error page with invalid state parameter" do
    get "/aven/oauth/github/callback", params: { code: "test_code", state: "wrong_state" }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Invalid state parameter"
  end

  test "handles token exchange failure" do
    # Initiate OAuth flow
    get "/aven/oauth/github"
    stored_state = session[:oauth_state]

    # Mock failed token exchange
    stub_request(:post, "https://github.com/login/oauth/access_token")
      .to_return(status: 400, body: "Bad Request")

    get "/aven/oauth/github/callback", params: { code: "test_code", state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "OAuth request failed"
  end

  test "handles user info fetch failure" do
    # Initiate OAuth flow
    get "/aven/oauth/github"
    stored_state = session[:oauth_state]

    # Mock successful token exchange
    stub_request(:post, "https://github.com/login/oauth/access_token")
      .to_return(
        status: 200,
        body: { access_token: "github_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock failed user info fetch
    stub_request(:get, "https://api.github.com/user")
      .to_return(status: 401, body: "Unauthorized")

    get "/aven/oauth/github/callback", params: { code: "test_code", state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "GitHub API request failed"
  end

  test "handles invalid email format" do
    # Initiate OAuth flow
    get "/aven/oauth/github"
    stored_state = session[:oauth_state]

    # Mock successful OAuth responses but with invalid email
    stub_request(:post, "https://github.com/login/oauth/access_token")
      .to_return(
        status: 200,
        body: { access_token: "github_token", token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://api.github.com/user")
      .to_return(
        status: 200,
        body: {
          id: 789456,
          email: "invalid-email",  # Invalid email format
          name: "GitHub User",
          avatar_url: "https://github.com/avatar.jpg",
          login: "githubuser"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/github/callback", params: { code: "test_code", state: stored_state }

    assert_response :ok
    assert_includes response.body, "Authentication Failed"
    assert_includes response.body, "Email is invalid"
  end
end
