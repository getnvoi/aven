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
module Aven
  class ItemRecipient < ApplicationRecord
    self.table_name = 'aven_item_recipients'

    # ACL references
    belongs_to :source_item, class_name: 'Aven::Item', optional: true
    belongs_to :target_item, class_name: 'Aven::Item', optional: true
    belongs_to :user, class_name: 'Aven::User', optional: true

    # Workspace & creator
    belongs_to :workspace, class_name: 'Aven::Workspace'
    belongs_to :created_by, class_name: 'Aven::User'

    # Delegation
    belongs_to :delegated_from_recipient, class_name: 'Aven::ItemRecipient', optional: true
    has_many :delegated_recipients, class_name: 'Aven::ItemRecipient', foreign_key: :delegated_from_recipient_id

    # Linking
    belongs_to :invitee, class_name: 'Aven::User', optional: true

    # Notifications
    has_many :invites, class_name: 'Aven::Invite', dependent: :destroy
  end
end
