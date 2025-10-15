require "rails_helper"

RSpec.describe Aven::Oauth::GithubController, type: :request do
  before do
    # Configure OAuth for testing
    Aven.configuration.configure_oauth(:github, {
      client_id: "test_github_client_id",
      client_secret: "test_github_client_secret"
    })
  end

  describe "GET /aven/oauth/github" do
    it "redirects to GitHub OAuth authorization URL" do
      get "/aven/oauth/github"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("https://github.com/login/oauth/authorize")
      expect(response.location).to include("client_id=test_github_client_id")
      expect(response.location).to include("scope=user%3Aemail")
    end

    it "uses custom scope when configured" do
      Aven.configuration.configure_oauth(:github, {
        client_id: "test_github_client_id",
        client_secret: "test_github_client_secret",
        scope: "user,user:email,repo,workflow"
      })

      get "/aven/oauth/github"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("scope=user%2Cuser%3Aemail%2Crepo%2Cworkflow")
    end

    it "stores state in session" do
      get "/aven/oauth/github"
      expect(session[:oauth_state]).to be_present
    end
  end

  describe "GET /aven/oauth/github/callback" do
    let(:auth_code) { "test_github_auth_code" }

    before do
      # Initiate OAuth flow to set up session state
      get "/aven/oauth/github"
      @stored_state = session[:oauth_state]
    end

    context "with valid OAuth flow" do
      before do
        # Mock GitHub token exchange
        stub_request(:post, "https://github.com/login/oauth/access_token")
          .with(
            body: {
              client_id: "test_github_client_id",
              client_secret: "test_github_client_secret",
              code: auth_code,
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
      end

      it "creates a new user if not exists" do
        expect {
          get "/aven/oauth/github/callback", params: { code: auth_code, state: @stored_state }
        }.to change(Aven::User, :count).by(1)

        user = Aven::User.last
        expect(user.email).to eq("github@example.com")
        expect(user.remote_id).to eq("789456")
      end

      it "signs in existing user by email" do
        # Create existing user with same email but no remote_id
        existing_user = Aven::User.create!(
          email: "github@example.com",
          auth_tenant: "www.example.com",
          password: SecureRandom.hex(16)
        )

        expect {
          get "/aven/oauth/github/callback", params: { code: auth_code, state: @stored_state }
        }.not_to change(Aven::User, :count)

        existing_user.reload
        expect(existing_user.remote_id).to eq("789456")
        expect(existing_user.access_token).to eq("github_token")
        expect(response).to have_http_status(:redirect)
      end

      it "handles users without public email" do
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

        expect {
          get "/aven/oauth/github/callback", params: { code: auth_code, state: @stored_state }
        }.to change(Aven::User, :count).by(1)

        user = Aven::User.last
        expect(user.email).to eq("private@example.com")
        expect(user.remote_id).to eq("789456")
      end
    end

    context "with invalid state parameter" do
      it "renders error page" do
        get "/aven/oauth/github/callback", params: { code: auth_code, state: "wrong_state" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Invalid state parameter")
      end
    end

    context "when GitHub API returns error" do
      it "handles token exchange failure" do
        # Mock failed token exchange
        stub_request(:post, "https://github.com/login/oauth/access_token")
          .to_return(status: 400, body: "Bad Request")

        get "/aven/oauth/github/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("OAuth request failed")
      end

      it "handles user info fetch failure" do
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

        get "/aven/oauth/github/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("GitHub API request failed")
      end
    end

    context "when user save fails" do
      it "handles invalid email format" do
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

        get "/aven/oauth/github/callback", params: { code: auth_code, state: @stored_state }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Authentication Failed")
        expect(response.body).to include("Email is invalid")
      end
    end
  end
end
