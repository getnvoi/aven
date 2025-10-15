require "rails_helper"

RSpec.describe Aven::Oauth::GoogleController, type: :request do
  before do
    # Configure OAuth for testing
    Aven.configuration.configure_oauth(:google, {
      client_id: "test_client_id",
      client_secret: "test_client_secret"
    })
  end

  describe "GET /aven/oauth/google" do
    it "redirects to Google OAuth authorization URL" do
      get "/aven/oauth/google"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("https://accounts.google.com/o/oauth2/v2/auth")
      expect(response.location).to include("client_id=test_client_id")
      expect(response.location).to include("scope=openid+email+profile")
      expect(response.location).to include("response_type=code")
    end

    it "stores state in session" do
      get "/aven/oauth/google"
      expect(session[:oauth_state]).to be_present
    end
  end

  describe "GET /aven/oauth/google/callback" do
    let(:auth_code) { "test_auth_code" }

    before do
      # Initiate OAuth flow to set up session state
      get "/aven/oauth/google"
      @stored_state = session[:oauth_state]
    end

    context "with valid OAuth flow" do
      before do
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
      end

      it "creates a new user if not exists" do
        expect {
          get "/aven/oauth/google/callback", params: { code: auth_code, state: @stored_state }
        }.to change(Aven::User, :count).by(1)

        user = Aven::User.last
        expect(user.email).to eq("test@example.com")
        expect(user.remote_id).to eq("google_123")
      end

      it "signs in existing user" do
        # Create existing user
        existing_user = Aven::User.create!(
          email: "test@example.com",
          remote_id: "google_123",
          auth_tenant: "www.example.com",
          password: SecureRandom.hex(16)
        )

        expect {
          get "/aven/oauth/google/callback", params: { code: auth_code, state: @stored_state }
        }.not_to change(Aven::User, :count)

        expect(response).to have_http_status(:redirect)
      end

      it "updates access token for existing user" do
        existing_user = Aven::User.create!(
          email: "test@example.com",
          remote_id: "google_123",
          auth_tenant: "www.example.com",
          password: SecureRandom.hex(16)
        )

        get "/aven/oauth/google/callback", params: { code: auth_code, state: @stored_state }

        existing_user.reload
        expect(existing_user.access_token).to eq("test_token")
      end
    end

    context "with invalid state parameter" do
      it "renders error page" do
        get "/aven/oauth/google/callback", params: { code: auth_code, state: "wrong_state" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Invalid state parameter")
      end
    end

    context "when OAuth provider returns error" do
      it "handles token exchange failure" do
        # Mock failed token exchange
        stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
          .to_return(status: 400, body: { error: "invalid_grant" }.to_json)

        get "/aven/oauth/google/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("OAuth request failed")
      end

      it "handles user info fetch failure" do
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

        get "/aven/oauth/google/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("OAuth request failed")
      end
    end

    context "when user save fails" do
      it "handles missing email" do
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

        get "/aven/oauth/google/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Email can&#39;t be blank")
      end
    end
  end
end
