# frozen_string_literal: true

module Aven
  module System
    class ActivitiesController < BaseController
      def index
        @logs = Aven::Log.includes(:workspace).order(created_at: :desc)

        # Apply filters
        if params[:q].present?
          @logs = @logs.where("message ILIKE ?", "%#{params[:q]}%")
        end

        if params[:level].present?
          @logs = @logs.where(level: params[:level])
        end

        @logs = @logs.limit(100)

        view_component("system/activities/index", logs: @logs)
      end
    end
  end
end
