# frozen_string_literal: true

module Aven
  module Authentication
    extend ActiveSupport::Concern

    included do
      helper_method :current_user if respond_to?(:helper_method)
    end

    private
      # Returns the currently signed-in user, if any
      def current_user
        @current_user ||= Aven::User.find_by(id: session[:user_id]) if session[:user_id]
      end

      # Signs in the given user by setting the session
      def sign_in(user)
        reset_session
        session[:user_id] = user.id
        @current_user = user
      end

      # Signs out the current user by clearing the session
      def sign_out
        reset_session
        @current_user = nil
      end

      # Stores the current location to redirect back after authentication
      def store_location
        session[:return_to_after_authentication] = request.url if request.get?
      end

      # Returns and clears the stored location for redirect after authentication
      # This method accepts a resource parameter for API compatibility with Devise
      def stored_location_for(_resource = nil)
        session.delete(:return_to_after_authentication)
      end

      # Requires user to be authenticated, redirects to root if not
      def authenticate_user!
        unless current_user
          store_location
          redirect_to main_app.root_path, alert: "You must be signed in to access this page."
        end
      end
  end
end
