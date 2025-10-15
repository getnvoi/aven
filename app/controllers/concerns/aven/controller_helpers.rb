module Aven
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :current_workspace if respond_to?(:helper_method)
    end

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

    # Verify user has access to current workspace (similar to Devise's authenticate_user!)
    def verify_workspace!
      return unless current_user.present? && current_workspace.present?

      unless current_user.workspaces.exists?(id: current_workspace.id)
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
      end
    end
  end
end
