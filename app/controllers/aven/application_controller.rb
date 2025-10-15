module Aven
  class ApplicationController < ActionController::Base
    include Aven::ApplicationHelper

    helper_method :current_workspace

    # Get the current workspace from session
    def current_workspace
      return @current_workspace if defined?(@current_workspace)

      @current_workspace = if session[:workspace_id].present? && current_user
        current_user.workspaces.find_by(id: session[:workspace_id])
      elsif current_user
        # Auto-select first workspace if none selected
        workspace = current_user.workspaces.first
        session[:workspace_id] = workspace&.id
        workspace
      end
    end

    # Set the current workspace
    def current_workspace=(workspace)
      @current_workspace = workspace
      session[:workspace_id] = workspace&.id
    end
  end
end
