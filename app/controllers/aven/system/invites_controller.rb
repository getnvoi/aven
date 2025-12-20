# frozen_string_literal: true

module Aven
  module System
    class InvitesController < BaseController
      def index
        @invites = Aven::Invite.includes(:workspace)

        # Apply search
        @invites = params[:q].present? ? @invites.search(params[:q]) : @invites.order(created_at: :desc)

        # Apply filters
        @invites = @invites.where(invite_type: params[:invite_type]) if params[:invite_type].present?
        @invites = @invites.where(status: params[:status]) if params[:status].present?

        # Paginate
        @invites = @invites.page(params[:page]).per(params[:per_page] || 25)

        view_component("system/invites/index", invites: @invites)
      end
    end
  end
end
