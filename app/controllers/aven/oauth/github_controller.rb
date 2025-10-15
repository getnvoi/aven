# frozen_string_literal: true

require "net/http"
require "json"

module Aven
  module Oauth
    class GithubController < BaseController
      AUTHORIZATION_URL = "https://github.com/login/oauth/authorize"
      TOKEN_URL = "https://github.com/login/oauth/access_token"
      USER_INFO_URL = "https://api.github.com/user"
      USER_EMAIL_URL = "https://api.github.com/user/emails"
      DEFAULT_SCOPE = "user:email"

      protected

        def authorization_url(state)
          params = {
            client_id: oauth_config[:client_id],
            redirect_uri: callback_url,
            scope: oauth_config[:scope] || DEFAULT_SCOPE,
            state:
          }

          "#{AUTHORIZATION_URL}?#{params.to_query}"
        end

        def exchange_code_for_token(code)
          params = {
            client_id: oauth_config[:client_id],
            client_secret: oauth_config[:client_secret],
            code:,
            redirect_uri: callback_url
          }

          headers = { "Accept" => "application/json" }
          oauth_request(URI(TOKEN_URL), params, headers)
        end

        def fetch_user_info(access_token)
          # Fetch user profile
          user_data = github_api_request(USER_INFO_URL, access_token)

          # Fetch primary email if not public
          email = user_data[:email]
          if email.blank?
            emails_data = github_api_request(USER_EMAIL_URL, access_token)
            primary_email = emails_data.find { |e| e[:primary] && e[:verified] }
            email = primary_email[:email] if primary_email
          end

          {
            id: user_data[:id],
            email:,
            name: user_data[:name] || user_data[:login],
            avatar_url: user_data[:avatar_url],
            login: user_data[:login]
          }
        end

      private

        def callback_url
          aven.oauth_github_callback_url(host: request.host, protocol: request.protocol)
        end

        def oauth_config
          @oauth_config ||= Aven.configuration.oauth_providers[:github] || raise("GitHub OAuth not configured")
        end

        def github_api_request(url, access_token)
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

          request = Net::HTTP::Get.new(uri)
          request["Authorization"] = "Bearer #{access_token}"
          request["Accept"] = "application/vnd.github.v3+json"

          response = http.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            raise StandardError, "GitHub API request failed: #{response.body}"
          end

          JSON.parse(response.body, symbolize_names: true)
        end
    end
  end
end
