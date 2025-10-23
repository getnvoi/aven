require "test_helper"

class Aven::OauthLambdaIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = Aven::User.create!(
      email: "lambda@example.com",
      auth_tenant: "www.example.com",
      remote_id: "lambda_123"
    )
  end

  test "OAuth redirect uses lambda authenticated_root_path" do
    # Configure with a lambda
    Aven.configuration.authenticated_root_path = -> { "/custom/dashboard" }

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
          sub: @user.remote_id,
          email: @user.email,
          name: "Test User"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: "test_code", state: stored_state }

    # Should redirect to the lambda's return value
    assert_redirected_to "/custom/dashboard"
  ensure
    # Reset configuration after test
    Aven.configuration.authenticated_root_path = nil
  end

  test "OAuth redirect uses string authenticated_root_path" do
    # Configure with a string (backward compatibility)
    Aven.configuration.authenticated_root_path = "/static/dashboard"

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
          sub: @user.remote_id,
          email: @user.email,
          name: "Test User"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: "test_code", state: stored_state }

    # Should redirect to the string value
    assert_redirected_to "/static/dashboard"
  ensure
    # Reset configuration after test
    Aven.configuration.authenticated_root_path = nil
  end

  test "OAuth redirect falls back to root when authenticated_root_path is nil" do
    # Don't configure authenticated_root_path
    Aven.configuration.authenticated_root_path = nil

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
          sub: @user.remote_id,
          email: @user.email,
          name: "Test User"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: "test_code", state: stored_state }

    # Should redirect to root (fallback)
    assert_response :redirect
  end
end
