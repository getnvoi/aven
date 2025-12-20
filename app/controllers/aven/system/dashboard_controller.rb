# frozen_string_literal: true

module Aven
  module System
    class DashboardController < BaseController
      def index
        stats = {
          total_users: Aven::User.count,
          total_workspaces: Aven::Workspace.count,
          total_features: Aven::Feature.count,
          active_invites: Aven::Invite.where.not(status: 'completed').count
        }

        recent_activities = Aven::Log.order(created_at: :desc).limit(10)

        view_component("system/dashboard/index", stats:, recent_activities:)
      end
    end
  end
end
