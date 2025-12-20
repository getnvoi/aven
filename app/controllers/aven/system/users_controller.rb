# frozen_string_literal: true

module Aven
  module System
    class UsersController < BaseController
      def index
        @users = Aven::User.includes(:workspaces).order(created_at: :desc)

        # Apply filters
        if params[:q].present?
          @users = @users.where("email ILIKE ?", "%#{params[:q]}%")
        end

        if params[:admin].present?
          @users = @users.where(admin: params[:admin] == "true")
        end

        @users = @users.limit(100)

        view_component("system/users/index", users: @users)
      end
    end
  end
end
