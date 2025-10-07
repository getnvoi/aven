# frozen_string_literal: true

module Sqema
  class AuthController < ApplicationController
    AVAILABLE_PROVIDERS = %w[google_oauth2]

    def authenticate
      provider = params[:provider].to_s

      raise(StandardError, "invalid provider") unless AVAILABLE_PROVIDERS.include?(provider)

      redirect_post(
        send("user_#{provider}_omniauth_authorize_path"),
        params: { authenticity_token: form_authenticity_token }
      )
    end

    def google_oauth2
      handle_omniauth("google_oauth2")
    end

    def passthru
      logout if request.method == "GET"
    end

    def failure
      logout if request.method == "GET"
    end

    def logout
      sign_out(current_user) if current_user
      reset_session
      redirect_to after_sign_out_path_for(nil)
    end

    private

    def handle_omniauth(kind)
      auth_tenant = request.host # or however you determine tenant
      user = Sqema::User.create_from_omniauth!(request.env, auth_tenant)

      if user.persisted?
        sign_in_and_redirect user, event: :authentication
        #set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
      else
        session["devise.auth"] = request.env["omniauth.auth"].except(:extra)
        redirect_to new_user_registration_url
      end
    end

    def after_sign_in_path_for(resource)
      # This can be overridden by the host application
      stored_location_for(resource) || root_path
    end
    
    def after_sign_out_path_for(resource_or_scope)
      # This can be overridden by the host application
      root_path
    end
  end
end