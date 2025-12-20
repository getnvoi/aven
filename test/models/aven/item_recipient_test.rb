# == Schema Information
#
# Table name: aven_item_recipients
#
#  id                          :bigint           not null, primary key
#  allow_delegate              :boolean          default(FALSE)
#  completed_at                :datetime
#  completion_state            :string           default("pending")
#  otp_sent_at                 :datetime
#  position                    :integer          default(0)
#  security_level              :string           default("none")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  created_by_id               :bigint           not null
#  delegated_from_recipient_id :bigint
#  invitee_id                  :bigint
#  source_item_id              :bigint
#  target_item_id              :bigint
#  user_id                     :bigint
#  workspace_id                :bigint           not null
#
# Indexes
#
#  index_aven_item_recipients_on_completion_state             (completion_state)
#  index_aven_item_recipients_on_created_by_id                (created_by_id)
#  index_aven_item_recipients_on_delegated_from_recipient_id  (delegated_from_recipient_id)
#  index_aven_item_recipients_on_invitee_id                   (invitee_id)
#  index_aven_item_recipients_on_source_item_id               (source_item_id)
#  index_aven_item_recipients_on_target_item_id               (target_item_id)
#  index_aven_item_recipients_on_user_id                      (user_id)
#  index_aven_item_recipients_on_workspace_id                 (workspace_id)
#  index_item_recipients_source_target                        (source_item_id,target_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => aven_users.id)
#  fk_rails_...  (delegated_from_recipient_id => aven_item_recipients.id)
#  fk_rails_...  (invitee_id => aven_users.id)
#  fk_rails_...  (source_item_id => aven_items.id)
#  fk_rails_...  (target_item_id => aven_items.id)
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

module Aven
  class ItemRecipientTest < ActiveSupport::TestCase
    def setup
      @workspace = aven_workspaces(:one)
      @creator = aven_users(:one)
      @source_item = aven_items(:company_one)
      @target_item = aven_items(:contact_one)
    end

    test "valid item recipient" do
      recipient = ItemRecipient.new(
        source_item: @source_item,
        target_item: @target_item,
        workspace: @workspace,
        created_by: @creator
      )
      assert recipient.valid?
    end

    test "requires workspace" do
      recipient = ItemRecipient.new(
        source_item: @source_item,
        target_item: @target_item,
        created_by: @creator
      )
      assert_not recipient.valid?
      assert_includes recipient.errors[:workspace], "must exist"
    end

    test "requires created_by" do
      recipient = ItemRecipient.new(
        source_item: @source_item,
        target_item: @target_item,
        workspace: @workspace
      )
      assert_not recipient.valid?
      assert_includes recipient.errors[:created_by], "must exist"
    end

    test "source_item is optional" do
      recipient = ItemRecipient.new(
        target_item: @target_item,
        workspace: @workspace,
        created_by: @creator
      )
      assert recipient.valid?
    end

    test "target_item is optional" do
      recipient = ItemRecipient.new(
        source_item: @source_item,
        workspace: @workspace,
        created_by: @creator
      )
      assert recipient.valid?
    end

    test "user is optional" do
      recipient = ItemRecipient.new(
        source_item: @source_item,
        target_item: @target_item,
        workspace: @workspace,
        created_by: @creator,
        user: nil
      )
      assert recipient.valid?
    end

    test "has default values" do
      recipient = ItemRecipient.create!(
        source_item: @source_item,
        target_item: @target_item,
        workspace: @workspace,
        created_by: @creator
      )

      assert_equal 0, recipient.position
      assert_equal 'none', recipient.security_level
      assert_equal 'pending', recipient.completion_state
      assert_equal false, recipient.allow_delegate
    end

    # Association tests
    test "belongs to source_item" do
      recipient = aven_item_recipients(:recipient_one)
      assert_equal aven_items(:company_one), recipient.source_item
    end

    test "belongs to target_item" do
      recipient = aven_item_recipients(:recipient_one)
      assert_equal aven_items(:contact_one), recipient.target_item
    end

    test "belongs to workspace" do
      recipient = aven_item_recipients(:recipient_one)
      assert_equal aven_workspaces(:one), recipient.workspace
    end

    test "belongs to created_by" do
      recipient = aven_item_recipients(:recipient_one)
      assert_equal aven_users(:one), recipient.created_by
    end

    test "belongs to user when set" do
      recipient = aven_item_recipients(:recipient_with_user)
      assert_equal aven_users(:two), recipient.user
    end

    test "belongs to invitee when set" do
      recipient = aven_item_recipients(:recipient_one)
      recipient.update!(invitee: aven_users(:two))
      assert_equal aven_users(:two), recipient.invitee
    end

    test "belongs to delegated_from_recipient when set" do
      recipient = aven_item_recipients(:recipient_delegated)
      assert_equal aven_item_recipients(:recipient_one), recipient.delegated_from_recipient
    end

    test "has many delegated_recipients" do
      recipient = aven_item_recipients(:recipient_one)
      assert_includes recipient.delegated_recipients, aven_item_recipients(:recipient_delegated)
    end

    test "has many invites" do
      recipient = aven_item_recipients(:recipient_one)
      assert_includes recipient.invites, aven_invites(:fulfillment_invite_one)
      assert_includes recipient.invites, aven_invites(:reminder_invite)
    end

    test "destroys dependent invites" do
      recipient = aven_item_recipients(:recipient_completed)

      # First create an invite for this recipient to test the dependent destroy
      invite = Aven::Invite.create!(
        item_recipient: recipient,
        workspace: recipient.workspace,
        invite_type: 'fulfillment',
        invitee_email: 'test@example.com',
        auth_link_hash: 'test_unique_hash_for_destroy'
      )

      assert_difference 'Aven::Invite.count', -1 do
        recipient.destroy
      end

      assert_nil Aven::Invite.find_by(id: invite.id)
    end

    # Delegation chain test
    test "delegation chain" do
      original = aven_item_recipients(:recipient_one)
      delegated = aven_item_recipients(:recipient_delegated)

      assert_nil original.delegated_from_recipient
      assert_equal original, delegated.delegated_from_recipient
      assert_includes original.delegated_recipients, delegated
    end
  end
end
