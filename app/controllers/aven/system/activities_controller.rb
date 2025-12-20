# frozen_string_literal: true

module Aven
  module System
    class ActivitiesController < BaseController
      def index
        @logs = Aven::Log.includes(:workspace)

        # Apply search
        @logs = params[:q].present? ? @logs.search(params[:q]) : @logs.order(created_at: :desc)

        # Apply filters
        @logs = @logs.where(level: params[:level]) if params[:level].present?

        # Paginate
        @logs = @logs.page(params[:page]).per(params[:per_page] || 25)

        view_component("system/activities/index", logs: @logs)
      end
    end
  end
end
