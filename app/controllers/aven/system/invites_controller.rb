# frozen_string_literal: true

module Aven
  module System
    class InvitesController < BaseController
      def index
        @invites = Aven::Invite.includes(:workspace).order(created_at: :desc)

        # Apply filters
        if params[:q].present?
          @invites = @invites.where("invitee_email ILIKE ?", "%#{params[:q]}%")
        end

        if params[:invite_type].present?
          @invites = @invites.where(invite_type: params[:invite_type])
        end

        if params[:status].present?
          @invites = @invites.where(status: params[:status])
        end

        @invites = @invites.limit(100)

        view_component("system/invites/index", invites: @invites)
      end
    end
  end
end
