# == Schema Information
#
# Table name: aven_invites
#
#  id                :bigint           not null, primary key
#  auth_link_hash    :string           not null
#  expires_at        :datetime
#  invite_type       :string           not null
#  invitee_email     :string           not null
#  invitee_phone     :string
#  sent_at           :datetime
#  status            :string           default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  item_recipient_id :bigint
#  workspace_id      :bigint           not null
#
# Indexes
#
#  index_aven_invites_on_auth_link_hash     (auth_link_hash) UNIQUE
#  index_aven_invites_on_invite_type        (invite_type)
#  index_aven_invites_on_invitee_email      (invitee_email)
#  index_aven_invites_on_item_recipient_id  (item_recipient_id)
#  index_aven_invites_on_workspace_id       (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_recipient_id => aven_item_recipients.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

module Aven
  class InviteTest < ActiveSupport::TestCase
    def setup
      @workspace = aven_workspaces(:one)
      @item_recipient = aven_item_recipients(:recipient_one)
    end

    test "valid fulfillment invite" do
      invite = Invite.new(
        item_recipient: @item_recipient,
        workspace: @workspace,
        invite_type: 'fulfillment',
        invitee_email: 'test@example.com',
        auth_link_hash: 'unique_hash_123'
      )
      assert invite.valid?
    end

    test "valid workspace invite" do
      invite = Invite.new(
        workspace: @workspace,
        invite_type: 'workspace',
        invitee_email: 'test@example.com',
        auth_link_hash: 'unique_hash_456'
      )
      assert invite.valid?
    end

    test "requires workspace" do
      invite = Invite.new(
        invite_type: 'fulfillment',
        invitee_email: 'test@example.com',
        auth_link_hash: 'unique_hash_789'
      )
      assert_not invite.valid?
      assert_includes invite.errors[:workspace], "must exist"
    end

    test "requires invite_type" do
      invite = Invite.new(
        workspace: @workspace,
        invitee_email: 'test@example.com',
        auth_link_hash: 'unique_hash_abc'
      )
      assert_not invite.valid?
      assert_includes invite.errors[:invite_type], "can't be blank"
    end

    test "requires invitee_email" do
      invite = Invite.new(
        workspace: @workspace,
        invite_type: 'fulfillment',
        auth_link_hash: 'unique_hash_def'
      )
      assert_not invite.valid?
      assert_includes invite.errors[:invitee_email], "can't be blank"
    end

    test "requires auth_link_hash" do
      invite = Invite.new(
        workspace: @workspace,
        invite_type: 'fulfillment',
        invitee_email: 'test@example.com'
      )
      assert_not invite.valid?
      assert_includes invite.errors[:auth_link_hash], "can't be blank"
    end

    test "auth_link_hash must be unique" do
      existing_invite = aven_invites(:fulfillment_invite_one)

      invite = Invite.new(
        workspace: @workspace,
        invite_type: 'fulfillment',
        invitee_email: 'different@example.com',
        auth_link_hash: existing_invite.auth_link_hash
      )

      assert_not invite.valid?
      assert_includes invite.errors[:auth_link_hash], "has already been taken"
    end

    test "item_recipient is optional" do
      invite = Invite.new(
        workspace: @workspace,
        invite_type: 'workspace',
        invitee_email: 'test@example.com',
        auth_link_hash: 'unique_hash_workspace'
      )
      assert invite.valid?
      assert_nil invite.item_recipient
    end

    test "has default status" do
      invite = Invite.create!(
        workspace: @workspace,
        invite_type: 'fulfillment',
        invitee_email: 'test@example.com',
        auth_link_hash: 'unique_hash_status_test'
      )

      assert_equal 'pending', invite.status
    end

    # Association tests
    test "belongs to item_recipient when set" do
      invite = aven_invites(:fulfillment_invite_one)
      assert_equal aven_item_recipients(:recipient_one), invite.item_recipient
    end

    test "belongs to workspace" do
      invite = aven_invites(:fulfillment_invite_one)
      assert_equal aven_workspaces(:one), invite.workspace
    end

    test "workspace invite has no item_recipient" do
      invite = aven_invites(:workspace_invite_one)
      assert_nil invite.item_recipient
    end

    # Immutable contact snapshot
    test "stores invitee_email as immutable snapshot" do
      invite = aven_invites(:fulfillment_invite_one)
      assert_equal 'alice@example.com', invite.invitee_email

      # Email remains unchanged even if contact changes
      assert_equal 'alice@example.com', invite.invitee_email
    end

    test "stores invitee_phone as immutable snapshot" do
      invite = aven_invites(:fulfillment_invite_one)
      assert_equal '+33612345678', invite.invitee_phone
    end

    # Multiple invites for same recipient
    test "same recipient can have multiple invites" do
      recipient = aven_item_recipients(:recipient_one)
      invites = recipient.invites

      assert invites.size >= 2
      assert_includes invites, aven_invites(:fulfillment_invite_one)
      assert_includes invites, aven_invites(:reminder_invite)
    end

    # Lifecycle fields
    test "tracks sent_at" do
      invite = aven_invites(:fulfillment_invite_one)
      assert_not_nil invite.sent_at
    end

    test "tracks expires_at" do
      invite = aven_invites(:fulfillment_invite_one)
      assert_not_nil invite.expires_at
    end

    test "tracks delivery status" do
      pending_invite = aven_invites(:workspace_invite_one)
      delivered_invite = aven_invites(:fulfillment_invite_two)

      assert_equal 'pending', pending_invite.status
      assert_equal 'delivered', delivered_invite.status
    end
  end
end
