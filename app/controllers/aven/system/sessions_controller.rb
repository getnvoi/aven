# frozen_string_literal: true

module Aven
  module System
    class SessionsController < Aven::ApplicationController
      layout "aven/system"

      skip_before_action :verify_authenticity_token, only: :create
      before_action :redirect_if_authenticated, only: [:new, :create]

      # GET /system/login
      # Show the login form
      def new
        view_component("system/sessions/new")
      end

      # POST /system/login
      # Authenticate with email and password
      def create
        email = params[:email]&.strip&.downcase
        password = params[:password]

        if email.blank? || password.blank?
          view_component(
            "system/sessions/new",
            email: email,
            alert: "Please enter your email and password.",
            status: :unprocessable_entity
          )
          return
        end

        system_user = Aven::SystemUser.find_by(email: email)

        if system_user&.authenticate(password)
          session[:system_user_id] = system_user.id
          redirect_to after_sign_in_path, notice: "Welcome back, #{system_user.name || system_user.email}!"
        else
          view_component(
            "system/sessions/new",
            email: email,
            alert: "Invalid email or password.",
            status: :unprocessable_entity
          )
        end
      end

      # DELETE /system/logout
      # Sign out the system user
      def destroy
        session.delete(:system_user_id)
        redirect_to aven.system_login_path, notice: "You have been signed out."
      end

      private

      def redirect_if_authenticated
        if session[:system_user_id].present?
          redirect_to aven.system_root_path
        end
      end

      def after_sign_in_path
        stored_location || aven.system_root_path
      end

      def stored_location
        session.delete(:system_return_to)
      end
    end
  end
end
