# frozen_string_literal: true

module Aven
  module Auth
    class MagicLinksController < ApplicationController
      # Rate limit magic link requests
      rate_limit to: 10, within: 3.minutes, only: :create
      rate_limit to: 10, within: 15.minutes, only: :consume

      # GET /aven/auth/magic_link
      # Show the form to request a magic link
      def new
        # If already signed in, redirect to authenticated root
        if current_user
          redirect_to after_sign_in_path
          return
        end

        view_component("auth/magic_links/new", email: params[:email])
      end

      # POST /aven/auth/magic_link
      # Send a magic link to the user's email
      def create
        email = params[:email]&.strip&.downcase

        if email.blank?
          view_component(
            "auth/magic_links/new",
            email: params[:email],
            alert: "Please enter your email address."
          )
          return
        end

        # Find user by email and current tenant
        user = find_user_by_email(email)

        if user
          magic_link = user.magic_links.create!(purpose: :sign_in)

          # Send the magic link email
          Aven::MagicLinkMailer.sign_in_instructions(magic_link).deliver_later

          # In development, show the code in flash for easy testing
          serve_development_magic_link(magic_link)

          redirect_to auth_verify_magic_link_path, notice: "Check your email for a sign-in code."
        else
          # Don't reveal whether email exists - same message either way
          redirect_to auth_verify_magic_link_path, notice: "If that email exists, we sent a sign-in code."
        end
      end

      # GET /aven/auth/magic_link/verify
      # Show the form to enter the magic link code
      def verify
        view_component(
          "auth/magic_links/verify",
          code: params[:code],
          notice: flash[:notice],
          alert: flash[:alert],
          magic_link_code: flash[:magic_link_code]
        )
      end

      # POST /aven/auth/magic_link/consume
      # Verify the code and sign in the user
      def consume
        code = params[:code]

        if code.blank?
          view_component(
            "auth/magic_links/verify",
            code: nil,
            alert: "Please enter the code from your email."
          )
          return
        end

        magic_link = Aven::MagicLink.consume(code)

        if magic_link
          sign_in(magic_link.user)
          set_current_workspace_for(magic_link.user)
          redirect_to after_sign_in_path, notice: "You have been signed in successfully."
        else
          view_component(
            "auth/magic_links/verify",
            code: code,
            alert: "Invalid or expired code. Please try again."
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

          # Create default workspace if user has none
          if workspace.nil?
            workspace = Aven::Workspace.create!(label: "Default Workspace", created_by: user)
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

        # In development, show the magic link code in flash for easy testing
        def serve_development_magic_link(magic_link)
          if Rails.env.development?
            flash[:magic_link_code] = magic_link.code
          end
        end
    end
  end
end
