# frozen_string_literal: true

module Aven
  module System
    class WorkspacesController < BaseController
      def index
        @workspaces = Aven::Workspace.includes(:users)

        # Apply search
        @workspaces = params[:q].present? ? @workspaces.search(params[:q]) : @workspaces.order(created_at: :desc)

        # Paginate
        @workspaces = @workspaces.page(params[:page]).per(params[:per_page] || 25)

        view_component("system/workspaces/index", workspaces: @workspaces)
      end
    end
  end
end
