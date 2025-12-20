# frozen_string_literal: true

module Aven
  module Auth
    class SessionsController < ApplicationController
      include Aven::Authentication

      # Rate limit login attempts
      rate_limit to: 10, within: 3.minutes, only: :create

      # GET /aven/auth/login
      # Show the login form
      def new
        if current_user
          redirect_to after_sign_in_path
          return
        end

        view_component("auth/sessions/new")
      end

      # POST /aven/auth/login
      # Authenticate with email and password
      def create
        email = params[:email]&.strip&.downcase
        password = params[:password]

        if email.blank? || password.blank?
          view_component(
            "auth/sessions/new",
            email: email,
            alert: "Please enter your email and password.",
            status: :unprocessable_entity
          )
          return
        end

        user = find_user_by_email(email)

        if user&.password_set? && user.authenticate(password)
          sign_in(user)
          set_current_workspace_for(user)
          redirect_to after_sign_in_path, notice: "You have been signed in successfully."
        else
          view_component(
            "auth/sessions/new",
            email: email,
            alert: "Invalid email or password.",
            status: :unprocessable_entity
          )
        end
      end

      private

        def find_user_by_email(email)
          auth_tenant = request.host
          Aven::User.find_by(email: email, auth_tenant: auth_tenant)
        end

        def set_current_workspace_for(user)
          workspace = user.workspaces.first

          if workspace.nil?
            workspace = Aven::Workspace.create!(label: "Default Workspace")
            Aven::WorkspaceUser.create!(user: user, workspace: workspace)
            user.reload
          end

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
