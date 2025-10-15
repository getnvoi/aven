# frozen_string_literal: true

module Aven
  class WorkspacesController < ApplicationController
    before_action :authenticate_user!

    # POST /workspaces/:id/switch
    def switch
      workspace = current_user.workspaces.friendly.find(params[:id])
      self.current_workspace = workspace
      redirect_to after_switch_workspace_path, notice: "Switched to #{workspace.label}"
    end

    private

      def after_switch_workspace_path
        Aven.configuration.authenticated_root_path || root_path
      end
  end
end
