require "rails_helper"

RSpec.describe Aven::Oauth::Auth0Controller, type: :request do
  before do
    # Configure OAuth for testing
    Aven.configuration.configure_oauth(:auth0, {
      domain: "test-tenant.auth0.com",
      client_id: "test_auth0_client_id",
      client_secret: "test_auth0_client_secret"
    })
  end

  describe "GET /aven/oauth/auth0" do
    it "redirects to Auth0 OAuth authorization URL" do
      get "/aven/oauth/auth0"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("https://test-tenant.auth0.com/authorize")
      expect(response.location).to include("client_id=test_auth0_client_id")
      expect(response.location).to include("scope=openid+email+profile")
      expect(response.location).to include("response_type=code")
    end

    it "includes audience parameter when configured" do
      Aven.configuration.configure_oauth(:auth0, {
        domain: "test-tenant.auth0.com",
        client_id: "test_auth0_client_id",
        client_secret: "test_auth0_client_secret",
        audience: "https://api.example.com"
      })

      get "/aven/oauth/auth0"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("audience=https%3A%2F%2Fapi.example.com")
    end

    it "uses custom scope when configured" do
      Aven.configuration.configure_oauth(:auth0, {
        domain: "test-tenant.auth0.com",
        client_id: "test_auth0_client_id",
        client_secret: "test_auth0_client_secret",
        scope: "openid email profile read:users"
      })

      get "/aven/oauth/auth0"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("scope=openid+email+profile+read%3Ausers")
    end

    it "stores state in session" do
      get "/aven/oauth/auth0"
      expect(session[:oauth_state]).to be_present
    end
  end

  describe "GET /aven/oauth/auth0/callback" do
    let(:auth_code) { "test_auth0_auth_code" }

    before do
      # Initiate OAuth flow to set up session state
      get "/aven/oauth/auth0"
      @stored_state = session[:oauth_state]
    end

    context "with valid OAuth flow" do
      before do
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
      end

      it "creates a new user if not exists" do
        expect {
          get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }
        }.to change(Aven::User, :count).by(1)

        user = Aven::User.last
        expect(user.email).to eq("auth0user@example.com")
        expect(user.remote_id).to eq("auth0|123456789")
        expect(user.access_token).to eq("auth0_test_token")
      end

      it "signs in existing user by email" do
        # Create existing user with same email but no remote_id
        existing_user = Aven::User.create!(
          email: "auth0user@example.com",
          auth_tenant: "www.example.com",
          password: SecureRandom.hex(16)
        )

        expect {
          get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }
        }.not_to change(Aven::User, :count)

        existing_user.reload
        expect(existing_user.remote_id).to eq("auth0|123456789")
        expect(existing_user.access_token).to eq("auth0_test_token")
        expect(response).to have_http_status(:redirect)
      end

      it "signs in existing user by remote_id" do
        # Create existing user with same remote_id
        existing_user = Aven::User.create!(
          email: "auth0user@example.com",
          remote_id: "auth0|123456789",
          auth_tenant: "www.example.com",
          password: SecureRandom.hex(16)
        )

        expect {
          get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }
        }.not_to change(Aven::User, :count)

        existing_user.reload
        expect(existing_user.access_token).to eq("auth0_test_token")
        expect(response).to have_http_status(:redirect)
      end

      it "uses nickname as name fallback when name is missing" do
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

        expect {
          get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }
        }.to change(Aven::User, :count).by(1)

        user = Aven::User.last
        expect(user.email).to eq("auth0user@example.com")
      end
    end

    context "with invalid state parameter" do
      it "renders error page" do
        get "/aven/oauth/auth0/callback", params: { code: auth_code, state: "wrong_state" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Invalid state parameter")
      end
    end

    context "when Auth0 API returns error" do
      it "handles token exchange failure" do
        # Mock failed token exchange
        stub_request(:post, "https://test-tenant.auth0.com/oauth/token")
          .to_return(
            status: 400,
            body: { error: "invalid_grant", error_description: "Invalid authorization code" }.to_json
          )

        get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("OAuth request failed")
      end

      it "handles user info fetch failure" do
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

        get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("OAuth request failed")
      end
    end

    context "when user save fails" do
      it "handles invalid email format" do
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
              email: "invalid-email",  # Invalid email format
              name: "Auth0 Test User",
              picture: "https://s.gravatar.com/avatar/test.png"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Email is invalid")
      end

      it "handles missing email" do
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
              email: nil,  # Missing email
              name: "Auth0 Test User",
              picture: "https://s.gravatar.com/avatar/test.png"
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        get "/aven/oauth/auth0/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Email can&#39;t be blank")
      end
    end

    context "when Auth0 is not configured" do
      before do
        Aven.configuration.oauth_providers = {}
      end

      it "raises configuration error" do
        expect {
          get "/aven/oauth/auth0"
        }.to raise_error("Auth0 OAuth not configured")
      end
    end

    context "when Auth0 domain is not configured" do
      before do
        Aven.configuration.configure_oauth(:auth0, {
          client_id: "test_auth0_client_id",
          client_secret: "test_auth0_client_secret"
          # domain is missing
        })
      end

      it "raises configuration error" do
        expect {
          get "/aven/oauth/auth0"
        }.to raise_error("Auth0 domain not configured")
      end
    end
  end
end
