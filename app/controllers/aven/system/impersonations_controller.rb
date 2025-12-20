# frozen_string_literal: true

module Aven
  module System
    class ImpersonationsController < BaseController
      def create
        user = Aven::User.find(params[:user_id])

        # Store the system user ID to return to later
        session[:impersonated_from_system_user_id] = session[:system_user_id]

        # Clear system user session
        session.delete(:system_user_id)

        # Create a session for the impersonated user
        user_session = Aven::Session.create!(user:)
        session[:session_id] = user_session.session_id

        redirect_to "/", notice: "Now impersonating #{user.email}"
      end

      def destroy
        # Restore system user session
        if session[:impersonated_from_system_user_id]
          session[:system_user_id] = session.delete(:impersonated_from_system_user_id)
          session.delete(:session_id)
        end

        redirect_to aven.system_root_path, notice: "Stopped impersonating user"
      end
    end
  end
end
