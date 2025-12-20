# frozen_string_literal: true

module Aven
  module Auth
    class PasswordResetsController < ApplicationController
      include Aven::Authentication

      # Rate limit password reset requests
      rate_limit to: 5, within: 5.minutes, only: :create
      rate_limit to: 10, within: 15.minutes, only: :update

      # GET /aven/auth/password_reset
      # Show form to request password reset
      def new
        view_component("auth/password_resets/new")
      end

      # POST /aven/auth/password_reset
      # Send password reset email
      def create
        email = params[:email]&.strip&.downcase

        if email.blank?
          view_component(
            "auth/password_resets/new",
            email: params[:email],
            alert: "Please enter your email address.",
            status: :unprocessable_entity
          )
          return
        end

        user = find_user_by_email(email)

        if user
          # Generate password reset token and send email
          token = user.generate_token_for(:password_reset)
          Aven::PasswordResetMailer.reset_instructions(user, token).deliver_later
        end

        # Always show same message to prevent email enumeration
        redirect_to auth_login_path, notice: "If that email exists, we sent password reset instructions."
      end

      # GET /aven/auth/password_reset/edit?token=xxx
      # Show form to set new password
      def edit
        @token = params[:token]
        @user = Aven::User.find_by_token_for(:password_reset, @token)

        if @user.nil?
          redirect_to auth_password_reset_path, alert: "Invalid or expired password reset link."
          return
        end

        view_component("auth/password_resets/edit", token: @token)
      end

      # PATCH /aven/auth/password_reset
      # Update the password
      def update
        @token = params[:token]
        @user = Aven::User.find_by_token_for(:password_reset, @token)

        if @user.nil?
          redirect_to auth_password_reset_path, alert: "Invalid or expired password reset link."
          return
        end

        password = params[:password]
        password_confirmation = params[:password_confirmation]

        if password.blank?
          view_component(
            "auth/password_resets/edit",
            token: @token,
            alert: "Please enter a new password.",
            status: :unprocessable_entity
          )
          return
        end

        if password != password_confirmation
          view_component(
            "auth/password_resets/edit",
            token: @token,
            alert: "Password confirmation doesn't match.",
            status: :unprocessable_entity
          )
          return
        end

        @user.password = password

        if @user.save
          # Invalidate all existing sessions for security
          @user.sessions.destroy_all

          redirect_to auth_login_path, notice: "Your password has been reset. Please sign in."
        else
          view_component(
            "auth/password_resets/edit",
            token: @token,
            alert: @user.errors.full_messages.first,
            status: :unprocessable_entity
          )
        end
      end

      private

        def find_user_by_email(email)
          auth_tenant = request.host
          Aven::User.find_by(email: email, auth_tenant: auth_tenant)
        end
    end
  end
end
