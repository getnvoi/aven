# frozen_string_literal: true

module Aven
  class AuthController < ApplicationController
    def authenticate
      provider = params[:provider].to_s

      raise(StandardError, "invalid provider") unless configured_providers.include?(provider)

      redirect_post(
        send("user_#{provider}_omniauth_authorize_path"),
        params: { authenticity_token: form_authenticity_token }
      )
    end

    def action_missing(action_name)
      if configured_providers.include?(action_name.to_s)
        handle_omniauth(action_name.to_s)
      else
        raise AbstractController::ActionNotFound, "The action '#{action_name}' could not be found for #{self.class.name}"
      end
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

    def configured_providers
      @configured_providers ||= Aven.configuration.auth.providers.map { |p| p[:provider].to_s }
    end

    def handle_omniauth(kind)
      auth_tenant = request.host # or however you determine tenant
      user = Aven::User.create_from_omniauth!(request.env, auth_tenant)

      if user.persisted?
        sign_in_and_redirect user, event: :authentication
      else
        session["devise.auth"] = request.env["omniauth.auth"].except(:extra)
        redirect_to new_user_registration_url
      end
    end

    def after_sign_in_path_for(resource)
      stored_location_for(resource) || Aven.configuration.authenticated_root_path || root_path
    end

    def after_sign_out_path_for(resource_or_scope)
      Aven.configuration.authenticated_root_path || root_path
    end
  end
end