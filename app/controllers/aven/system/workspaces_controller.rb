# frozen_string_literal: true

module Aven
  module System
    class WorkspacesController < BaseController
      def index
        @workspaces = Aven::Workspace.includes(:users).order(created_at: :desc)

        # Apply filters
        if params[:q].present?
          @workspaces = @workspaces.where("label ILIKE ? OR slug ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
        end

        @workspaces = @workspaces.limit(100)

        view_component("system/workspaces/index", workspaces: @workspaces)
      end
    end
  end
end
