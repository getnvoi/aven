# frozen_string_literal: true

module Aven
  module Oauth
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:callback]

      # Initiates OAuth flow
      def create
        state = SecureRandom.hex(16)
        session[:oauth_state] = state

        redirect_to authorization_url(state), allow_other_host: true
      end

      # Handles OAuth callback
      def callback
        validate_state!

        token_data = exchange_code_for_token(params[:code])
        user_info = fetch_user_info(token_data[:access_token])

        user = find_or_create_user(user_info, token_data)

        if user.persisted?
          sign_in_and_redirect(user)
        else
          handle_failed_authentication(user)
        end
      rescue => e
        Rails.logger.error("OAuth authentication failed: #{e.class.name} - #{e.message}")
        Rails.logger.error(e.backtrace.first(10).join("\n")) unless Rails.env.production?

        error_message = if Rails.env.production?
          "Authentication failed. Please try again."
        else
          "#{e.message}"
        end

        error_class = Rails.env.production? ? nil : e.class.name
        render_error_page(error_message, error_class)
      end

      # Renders OAuth error page
      def error
        @error_message = params[:message] || "Authentication failed"
        @error_class = params[:error_class]

        view_component(
          "oauth/error",
          error_message: @error_message,
          error_class: @error_class,
          current_user:
        )
      end

      protected

        # Must be implemented by subclasses
        def authorization_url(state)
          raise NotImplementedError
        end

        def exchange_code_for_token(code)
          raise NotImplementedError
        end

        def fetch_user_info(access_token)
          raise NotImplementedError
        end

        # Common helper methods
        def validate_state!
          if params[:state] != session[:oauth_state]
            raise StandardError, "Invalid state parameter"
          end
          session.delete(:oauth_state)
        end

        def find_or_create_user(user_info, token_data)
          auth_tenant = request.host

          user = Aven::User.where(auth_tenant:)
                           .where("remote_id = ? OR email = ?", user_info[:id], user_info[:email])
                           .first_or_initialize

          user.tap do |u|
            u.auth_tenant = auth_tenant
            u.remote_id = user_info[:id].to_s
            u.email = user_info[:email]
            u.access_token = token_data[:access_token]
            u.password = SecureRandom.hex(16) if u.new_record?
            u.save
          end
        end

        def sign_in_and_redirect(user)
          sign_in(user, scope: :user)
          redirect_to after_sign_in_path_for(user)
        end

        def handle_failed_authentication(user)
          error_message = if !Rails.env.production? && user.errors.any?
            user.errors.full_messages.join(", ")
          else
            "Failed to create user account"
          end

          error_class = Rails.env.production? ? nil : "User::ValidationError"
          render_error_page(error_message, error_class)
        end

        def render_error_page(message, error_class = nil)
          view_component(
            "oauth/error",
            error_message: message,
            error_class:,
            current_user:
          )
        end

        def after_sign_in_path_for(resource)
          stored_location_for(resource) ||
            Aven.configuration.authenticated_root_path ||
            begin
              main_app.root_path
            rescue NoMethodError
              root_path
            end
        end

        # HTTP helper for OAuth requests
        def oauth_request(uri, params, headers = {})
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

          request = Net::HTTP::Post.new(uri)
          request.set_form_data(params)
          headers.each { |key, value| request[key] = value }

          response = http.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            raise StandardError, "OAuth request failed: #{response.body}"
          end

          JSON.parse(response.body, symbolize_names: true)
        end

        def oauth_get_request(uri, access_token)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

          request = Net::HTTP::Get.new(uri)
          request["Authorization"] = "Bearer #{access_token}"

          response = http.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            raise StandardError, "OAuth request failed: #{response.body}"
          end

          JSON.parse(response.body, symbolize_names: true)
        end
    end
  end
end
