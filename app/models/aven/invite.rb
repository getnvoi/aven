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
module Aven
  class Invite < ApplicationRecord
    self.table_name = 'aven_invites'

    # Links
    belongs_to :item_recipient, class_name: 'Aven::ItemRecipient', optional: true
    belongs_to :workspace, class_name: 'Aven::Workspace'

    # Validations
    validates :invite_type, presence: true
    validates :invitee_email, presence: true
    validates :auth_link_hash, presence: true, uniqueness: true
  end
end
