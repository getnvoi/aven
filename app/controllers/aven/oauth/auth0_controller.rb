# frozen_string_literal: true

require "net/http"
require "json"

module Aven
  module Oauth
    class Auth0Controller < BaseController
      # Auth0 uses your domain (e.g., your-tenant.auth0.com or your-tenant.us.auth0.com)
      # These URLs will be constructed dynamically based on the configured domain
      DEFAULT_SCOPE = "openid email profile"

      protected

        def authorization_url(state)
          params = {
            client_id: oauth_config[:client_id],
            redirect_uri: callback_url,
            response_type: "code",
            scope: oauth_config[:scope] || DEFAULT_SCOPE,
            state:
          }

          # Optionally add audience parameter if specified (for API access)
          params[:audience] = oauth_config[:audience] if oauth_config[:audience].present?

          "#{auth0_authorization_url}?#{params.to_query}"
        end

        def exchange_code_for_token(code)
          params = {
            grant_type: "authorization_code",
            client_id: oauth_config[:client_id],
            client_secret: oauth_config[:client_secret],
            code:,
            redirect_uri: callback_url
          }

          oauth_request(URI(auth0_token_url), params)
        end

        def fetch_user_info(access_token)
          response = oauth_get_request(URI(auth0_userinfo_url), access_token)

          {
            id: response[:sub],
            email: response[:email],
            name: response[:name] || response[:nickname],
            picture: response[:picture]
          }
        end

      private

        def callback_url
          aven.oauth_auth0_callback_url(host: request.host, protocol: request.protocol)
        end

        def oauth_config
          @oauth_config ||= Aven.configuration.oauth_providers[:auth0] || raise("Auth0 OAuth not configured")
        end

        def auth0_domain
          @auth0_domain ||= oauth_config[:domain] || raise("Auth0 domain not configured")
        end

        def auth0_base_url
          @auth0_base_url ||= auth0_domain.start_with?("http") ? auth0_domain : "https://#{auth0_domain}"
        end

        def auth0_authorization_url
          "#{auth0_base_url}/authorize"
        end

        def auth0_token_url
          "#{auth0_base_url}/oauth/token"
        end

        def auth0_userinfo_url
          "#{auth0_base_url}/userinfo"
        end
    end
  end
end
