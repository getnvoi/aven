# frozen_string_literal: true

module Aven
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :current_workspace if respond_to?(:helper_method)
    end

    # Get the current workspace from Current context
    #
    # @return [Aven::Workspace, nil] the current workspace
    def current_workspace
      return Aven::Current.workspace if Aven::Current.workspace.present?

      # Try to restore from session if not set
      if session[:workspace_id].present? && current_user
        workspace = current_user.workspaces.find_by(id: session[:workspace_id])
        Aven::Current.workspace = workspace if workspace
        return workspace
      end

      # Auto-select first workspace if user has only one
      if current_user
        workspaces = current_user.workspaces
        if workspaces.any?
          workspace = workspaces.first
          self.current_workspace = workspace
          return workspace
        end
      end

      nil
    end

    # Set the current workspace
    #
    # @param workspace [Aven::Workspace, nil] the workspace to set
    def current_workspace=(workspace)
      Aven::Current.workspace = workspace
      session[:workspace_id] = workspace&.id
    end

    # Verify user has access to current workspace
    #
    # @return [void] renders 404 if user doesn't have access
    def verify_workspace!
      return unless current_user.present? && current_workspace.present?

      unless current_user.workspaces.exists?(id: current_workspace.id)
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
      end
    end

    # Execute block with a specific workspace context
    #
    # @param workspace [Aven::Workspace] the workspace to use
    # @yield the block to execute
    def with_workspace(workspace, &block)
      Aven::Current.with_workspace(workspace, &block)
    end
  end
end
