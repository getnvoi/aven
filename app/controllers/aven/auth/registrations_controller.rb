# frozen_string_literal: true

module Aven
  module Auth
    class RegistrationsController < ApplicationController
      include Aven::Authentication

      before_action :check_registration_enabled
      before_action :redirect_if_authenticated

      # Rate limit registration attempts
      rate_limit to: 5, within: 1.hour, only: :create

      # GET /aven/auth/register
      def new
        view_component("auth/registrations/new")
      end

      # POST /aven/auth/register
      def create
        email = params[:email]&.strip&.downcase
        password = params[:password]
        password_confirmation = params[:password_confirmation]

        if email.blank? || password.blank?
          view_component(
            "auth/registrations/new",
            email: email,
            alert: "Please enter your email and password.",
            status: :unprocessable_entity
          )
          return
        end

        if password != password_confirmation
          view_component(
            "auth/registrations/new",
            email: email,
            alert: "Passwords do not match.",
            status: :unprocessable_entity
          )
          return
        end

        if user_exists?(email)
          view_component(
            "auth/registrations/new",
            email: email,
            alert: "An account with this email already exists.",
            status: :unprocessable_entity
          )
          return
        end

        user = create_user(email:, password:, password_confirmation:)

        if user.persisted?
          sign_in(user)
          set_current_workspace_for(user)
          redirect_to after_sign_in_path, notice: "Your account has been created successfully."
        else
          view_component(
            "auth/registrations/new",
            email: email,
            alert: user.errors.full_messages.join(", "),
            status: :unprocessable_entity
          )
        end
      end

      private

        def check_registration_enabled
          unless Aven.configuration.enable_password_registration
            redirect_to auth_login_path, alert: "Registration is not available."
          end
        end

        def redirect_if_authenticated
          redirect_to after_sign_in_path if current_user
        end

        def user_exists?(email)
          Aven::User.exists?(email: email, auth_tenant: request.host)
        end

        def create_user(email:, password:, password_confirmation:)
          Aven::User.create(
            email: email,
            password: password,
            password_confirmation: password_confirmation,
            auth_tenant: request.host
          )
        end

        def set_current_workspace_for(user)
          workspace = Aven::Workspace.create!(label: "Default Workspace", created_by: user)
          Aven::WorkspaceUser.create!(user: user, workspace: workspace)
          user.reload
          self.current_workspace = workspace
        end

        def after_sign_in_path
          stored_location_for(nil) ||
            Aven.configuration.resolve_authenticated_root_path ||
            begin
              main_app.root_path
            rescue NoMethodError
              root_path
            end
        end
    end
  end
end
