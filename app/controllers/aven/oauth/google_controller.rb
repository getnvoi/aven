# frozen_string_literal: true

require "net/http"
require "json"

module Aven
  module Oauth
    class GoogleController < BaseController
      AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth"
      TOKEN_URL = "https://www.googleapis.com/oauth2/v4/token"
      USER_INFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"
      DEFAULT_SCOPE = "openid email profile"

      protected

        def authorization_url(state)
          params = {
            client_id: oauth_config[:client_id],
            redirect_uri: callback_url,
            response_type: "code",
            scope: oauth_config[:scope] || DEFAULT_SCOPE,
            state:,
            access_type: oauth_config[:access_type] || "offline",
            prompt: oauth_config[:prompt] || "select_account"
          }

          "#{AUTHORIZATION_URL}?#{params.to_query}"
        end

        def exchange_code_for_token(code)
          params = {
            code:,
            client_id: oauth_config[:client_id],
            client_secret: oauth_config[:client_secret],
            redirect_uri: callback_url,
            grant_type: "authorization_code"
          }

          oauth_request(URI(TOKEN_URL), params)
        end

        def fetch_user_info(access_token)
          response = oauth_get_request(URI(USER_INFO_URL), access_token)

          {
            id: response[:sub],
            email: response[:email],
            name: response[:name],
            picture: response[:picture]
          }
        end

      private

        def callback_url
          aven.oauth_google_callback_url(host: request.host, protocol: request.protocol)
        end

        def oauth_config
          @oauth_config ||= Aven.configuration.oauth_providers[:google] || raise("Google OAuth not configured")
        end
    end
  end
end
