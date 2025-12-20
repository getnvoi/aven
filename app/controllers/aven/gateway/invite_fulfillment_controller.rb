# frozen_string_literal: true

module Aven
  module Gateway
    class InviteFulfillmentController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:show]
      before_action :find_invite

      # GET /aven/g/i/:auth_link_hash
      def show
        if @invite.nil?
          render json: { error: "Invite not found" }, status: :not_found
          return
        end

        if expired?
          render json: { error: "Invite has expired" }, status: :gone
          return
        end

        render json: invite_data
      end

      private

        def find_invite
          @invite = Aven::Invite.find_by(auth_link_hash: params[:auth_link_hash])
        end

        def expired?
          @invite.expires_at.present? && @invite.expires_at < Time.current
        end

        def invite_data
          {
            id: @invite.id,
            invite_type: @invite.invite_type,
            invitee_email: @invite.invitee_email,
            status: @invite.status,
            expires_at: @invite.expires_at&.iso8601,
            workspace_id: @invite.workspace_id,
            item_recipient_id: @invite.item_recipient_id
          }
        end
    end
  end
end
