# frozen_string_literal: true

module Aven
  module Authentication
    extend ActiveSupport::Concern

    included do
      helper_method :current_user if respond_to?(:helper_method)
      before_action :set_current_request_details
      before_action :resume_session
    end

    private
      # Returns the currently signed-in user via Current
      def current_user
        Aven::Current.user
      end

      # Returns the current session via Current
      def current_session
        Aven::Current.session
      end

      # Signs in the given user by creating a new session
      #
      # @param user [Aven::User] the user to sign in
      # @return [Aven::Session] the created session
      def sign_in(user)
        # Prevent session fixation attacks
        reset_session

        # Create a new database-backed session
        session_record = user.sessions.create!(
          user_agent: request.user_agent,
          ip_address: request.remote_ip,
          last_active_at: Time.current
        )

        # Set signed, httponly cookie with session token
        set_session_cookie(session_record)

        # Set Current context
        Aven::Current.session = session_record

        session_record
      end

      # Signs out the current user by destroying the session
      def sign_out
        if current_session.present?
          current_session.destroy
        end

        delete_session_cookie
        reset_session
        Aven::Current.reset
      end

      # Resume session from cookie on each request
      def resume_session
        Aven::Current.session = find_session_by_cookie
        touch_session_activity if Aven::Current.session.present?
      end

      # Set request metadata on Current for audit/security
      def set_current_request_details
        Aven::Current.user_agent = request.user_agent
        Aven::Current.ip_address = request.remote_ip
        Aven::Current.request_id = request.request_id
      end

      # Find session by signed cookie
      #
      # @return [Aven::Session, nil] the session if found and valid
      def find_session_by_cookie
        return nil unless cookies.signed[:session_token].present?

        Aven::Session.find_by(id: cookies.signed[:session_token])
      end

      # Set signed, httponly, permanent cookie for session
      #
      # @param session_record [Aven::Session] the session to store
      def set_session_cookie(session_record)
        cookies.signed.permanent[:session_token] = {
          value: session_record.id,
          httponly: true,
          same_site: :lax
        }
      end

      # Delete the session cookie
      def delete_session_cookie
        cookies.delete(:session_token)
      end

      # Touch session activity (throttled to avoid DB hammering)
      def touch_session_activity
        Aven::Current.session.touch_activity!
      end

      # Stores the current location to redirect back after authentication
      def store_location
        session[:return_to_after_authentication] = request.url if request.get?
      end

      # Returns and clears the stored location for redirect after authentication
      # This method accepts a resource parameter for API compatibility with Devise
      #
      # @param _resource [Object] ignored, for Devise compatibility
      # @return [String, nil] the stored URL or nil
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

      # Check if there is an authenticated session
      #
      # @return [Boolean] true if authenticated
      def authenticated?
        Aven::Current.authenticated?
      end
  end
end
