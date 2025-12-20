# frozen_string_literal: true

require "test_helper"

module Aven
  module Gateway
    class InviteFulfillmentControllerTest < ActionDispatch::IntegrationTest
      test "shows invite with valid hash" do
        invite = aven_invites(:fulfillment_invite_one)

        get aven.gateway_invite_fulfillment_path(auth_link_hash: invite.auth_link_hash)

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal invite.id, json["id"]
        assert_equal invite.invitee_email, json["invitee_email"]
        assert_equal invite.invite_type, json["invite_type"]
      end

      test "returns not found for invalid hash" do
        get aven.gateway_invite_fulfillment_path(auth_link_hash: "INVALIDHASH")

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_equal "Invite not found", json["error"]
      end

      test "returns gone for expired invite" do
        invite = aven_invites(:fulfillment_invite_one)
        invite.update!(expires_at: 1.day.ago)

        get aven.gateway_invite_fulfillment_path(auth_link_hash: invite.auth_link_hash)

        assert_response :gone
        json = JSON.parse(response.body)
        assert_equal "Invite has expired", json["error"]
      end
    end
  end
end
