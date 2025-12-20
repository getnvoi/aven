# frozen_string_literal: true

module Aven
  module System
    class UsersController < BaseController
      def index
        @users = Aven::User.includes(:workspaces)

        # Apply search
        @users = params[:q].present? ? @users.search(params[:q]) : @users.order(created_at: :desc)

        # Apply filters
        @users = @users.where(admin: params[:admin] == "true") if params[:admin].present?

        # Paginate
        @users = @users.page(params[:page]).per(params[:per_page] || 25)

        view_component("system/users/index", users: @users)
      end
    end
  end
end
