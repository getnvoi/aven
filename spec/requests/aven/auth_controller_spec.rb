require "rails_helper"

RSpec.describe "Aven::AuthController", type: :request do
  before do
    # Mock the configuration
    allow(Aven.configuration.auth).to receive(:providers).and_return([
      { provider: :google_oauth2, args: [], options: {} }
    ])
  end

  describe "POST /aven/users/auth/:provider" do
    context "with valid provider" do
      it "redirects to the authorization path" do
        post "/aven/users/auth/google_oauth2"
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /aven/users/auth/:provider/callback" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        provider: "google_oauth2",
        uid: "123456",
        info: {
          email: "user@example.com",
          name: "Test User"
        }
      })
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
      Rails.application.env_config["omniauth.auth"] = auth_hash
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    context "when callback is invoked" do
      it "handles the omniauth callback via action_missing" do
        # This will fail if action_missing doesn't catch the dynamic provider action
        expect {
          get "/aven/users/auth/google_oauth2/callback"
        }.not_to raise_error
      end
    end
  end

  describe "#configured_providers" do
    it "returns the configured providers as array of strings" do
      controller = Aven::AuthController.new
      expect(controller.send(:configured_providers)).to eq(["google_oauth2"])
    end

    context "with different provider" do
      before do
        allow(Aven.configuration.auth).to receive(:providers).and_return([
          { provider: :github, args: [], options: {} }
        ])
      end

      it "returns the new configured provider" do
        controller = Aven::AuthController.new
        expect(controller.send(:configured_providers)).to eq(["github"])
      end
    end

    context "when multiple providers are configured" do
      before do
        allow(Aven.configuration.auth).to receive(:providers).and_return([
          { provider: :google_oauth2, args: [], options: {} },
          { provider: :github, args: [], options: {} }
        ])
      end

      it "returns all configured providers" do
        controller = Aven::AuthController.new
        expect(controller.send(:configured_providers)).to eq(["google_oauth2", "github"])
      end
    end
  end

  describe "#action_missing" do
    let(:controller) { Aven::AuthController.new }

    before do
      allow(controller).to receive(:handle_omniauth)
      allow(controller).to receive(:configured_providers).and_return(["google_oauth2", "github"])
    end

    context "when action matches a configured provider" do
      it "calls handle_omniauth with the provider" do
        expect(controller).to receive(:handle_omniauth).with("google_oauth2")
        controller.send(:action_missing, "google_oauth2")
      end
    end

    context "when action does not match any configured provider" do
      it "raises ActionNotFound" do
        expect {
          controller.send(:action_missing, "facebook")
        }.to raise_error(AbstractController::ActionNotFound)
      end
    end
  end
end
