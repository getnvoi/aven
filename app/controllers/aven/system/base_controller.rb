# frozen_string_literal: true

module Aven
  module System
    class BaseController < Aven::ApplicationController
      layout "aven/system"

      before_action :authenticate_system_user!

      private

      # Returns the currently signed-in system user
      def current_system_user
        @current_system_user ||= Aven::SystemUser.find_by(id: session[:system_user_id])
      end

      # Requires system user to be authenticated
      def authenticate_system_user!
        return if current_system_user

        store_location
        redirect_to aven.system_login_path, alert: "Please log in to access the system admin area."
      end

      # Check if there is an authenticated system user
      def authenticated_system_user?
        current_system_user.present?
      end

      # Store current location for redirect after login
      def store_location
        session[:system_return_to] = request.fullpath if request.get? && !request.xhr?
      end

      # Get stored location and clear it
      def stored_location
        session.delete(:system_return_to)
      end

      # Sign in the given system user
      def sign_in_system_user(system_user)
        session[:system_user_id] = system_user.id
      end

      # Sign out the current system user
      def sign_out_system_user
        session.delete(:system_user_id)
        @current_system_user = nil
      end

      helper_method :current_system_user, :authenticated_system_user?
    end
  end
end
