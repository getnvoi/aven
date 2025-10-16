# frozen_string_literal: true

require "net/http"
require "json"

module Aven
  module Oauth
    class EntraIdController < BaseController
      # Microsoft Entra ID (formerly Azure AD) OAuth endpoints
      # Supports both single-tenant and multi-tenant configurations
      #
      # MINIMAL_SCOPE: Authentication only (no Graph API access)
      # Use this for simple login without accessing user data beyond basic profile
      MINIMAL_SCOPE = "openid email profile"

      # DEFAULT_SCOPE: Includes Graph API access for contacts and email
      DEFAULT_SCOPE = "openid email profile User.Read Contacts.Read Mail.Send Mail.Read"

      protected

        def authorization_url(state)
          params = {
            client_id: oauth_config[:client_id],
            redirect_uri: callback_url,
            response_type: "code",
            scope: oauth_config[:scope] || DEFAULT_SCOPE,
            state:,
            response_mode: "query"
          }

          # Optionally add domain_hint for faster login
          params[:domain_hint] = oauth_config[:domain_hint] if oauth_config[:domain_hint].present?

          # Optionally add prompt parameter
          params[:prompt] = oauth_config[:prompt] if oauth_config[:prompt].present?

          "#{entra_authorization_url}?#{params.to_query}"
        end

        def exchange_code_for_token(code)
          params = {
            client_id: oauth_config[:client_id],
            client_secret: oauth_config[:client_secret],
            code:,
            redirect_uri: callback_url,
            grant_type: "authorization_code",
            scope: oauth_config[:scope] || DEFAULT_SCOPE
          }

          oauth_request(URI(entra_token_url), params)
        end

        def fetch_user_info(access_token)
          response = oauth_get_request(URI(entra_userinfo_url), access_token)

          {
            id: response[:id] || response[:sub],
            email: response[:mail] || response[:userPrincipalName] || response[:email],
            name: response[:displayName] || response[:name],
            picture: nil # Microsoft Graph doesn't return picture in userinfo by default
          }
        end

      private

        def callback_url
          aven.oauth_entra_id_callback_url(host: request.host, protocol: "https://")
        end

        def oauth_config
          @oauth_config ||= Aven.configuration.oauth_providers[:entra_id] || raise("Microsoft Entra ID OAuth not configured")
        end

        def tenant_id
          @tenant_id ||= oauth_config[:tenant_id] || "common"
        end

        def entra_authorization_url
          "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/authorize"
        end

        def entra_token_url
          "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
        end

        def entra_userinfo_url
          # Using Microsoft Graph API for user info
          "https://graph.microsoft.com/v1.0/me"
        end
    end
  end
end
