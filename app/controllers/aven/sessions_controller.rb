# frozen_string_literal: true

module Aven
  class SessionsController < ApplicationController
    include Aven::Authentication

    before_action :authenticate_user!

    # GET /aven/sessions
    # List all active sessions for the current user
    def index
      @sessions = current_user.sessions.recent
      @current_session_id = current_session&.id

      respond_to do |format|
        format.html { view_component("sessions/index", sessions: @sessions, current_session_id: @current_session_id) }
        format.json { render json: sessions_json(@sessions) }
      end
    end

    # DELETE /aven/sessions/:id
    # Revoke a specific session
    def destroy
      session_to_destroy = current_user.sessions.find(params[:id])

      if session_to_destroy.id == current_session&.id
        # Revoking current session = logout
        sign_out
        redirect_to root_path, notice: "You have been signed out."
      else
        session_to_destroy.destroy
        redirect_to sessions_path, notice: "Session revoked successfully."
      end
    end

    # DELETE /aven/sessions/revoke_all
    # Revoke all sessions except the current one
    def revoke_all
      current_user.sessions.where.not(id: current_session&.id).destroy_all
      redirect_to sessions_path, notice: "All other sessions have been revoked."
    end

    private

      def sessions_json(sessions)
        sessions.map do |s|
          {
            id: s.id,
            device_info: s.device_info,
            browser_info: s.browser_info,
            ip_address: s.ip_address,
            last_active_at: s.last_active_at,
            created_at: s.created_at,
            current: s.id == current_session&.id
          }
        end
      end
  end
end
