# == Schema Information
#
# Table name: aven_invites
#
#  id                        :bigint           not null, primary key
#  allow_delegate            :boolean          default(TRUE), not null
#  auth_link_hash            :string           not null
#  completion_state          :string           default("pending"), not null
#  expires_at                :datetime
#  invite_type               :string           not null
#  invitee_email             :string           not null
#  invitee_phone             :string
#  invitee_type              :string
#  inviter_type              :string
#  metadata                  :jsonb            default({})
#  otp_sent_at               :datetime
#  otp_type                  :string
#  otp_verified_at           :datetime
#  selected_phone_type       :string
#  sent_at                   :datetime
#  status                    :string           default("pending")
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  delegated_from_invite_id  :bigint
#  invitee_id                :bigint
#  inviter_id                :bigint
#  item_recipient_id         :bigint
#  recipient_workspace_id    :bigint
#  workspace_id              :bigint           not null
#
# Indexes
#
#  index_aven_invites_on_auth_link_hash              (auth_link_hash) UNIQUE
#  index_aven_invites_on_completion_state            (completion_state)
#  index_aven_invites_on_delegated_from_invite_id    (delegated_from_invite_id)
#  index_aven_invites_on_invite_type                 (invite_type)
#  index_aven_invites_on_invitee                     (invitee_type,invitee_id)
#  index_aven_invites_on_invitee_email               (invitee_email)
#  index_aven_invites_on_inviter                     (inviter_type,inviter_id)
#  index_aven_invites_on_item_recipient_id           (item_recipient_id)
#  index_aven_invites_on_metadata                    (metadata) USING gin
#  index_aven_invites_on_otp_verified_at             (otp_verified_at)
#  index_aven_invites_on_recipient_workspace_id      (recipient_workspace_id)
#  index_aven_invites_on_workspace_id                (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (delegated_from_invite_id => aven_invites.id)
#  fk_rails_...  (item_recipient_id => aven_item_recipients.id)
#  fk_rails_...  (recipient_workspace_id => aven_workspaces.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class Invite < ApplicationRecord
    self.table_name = 'aven_invites'

    # Virtual attributes for serialization
    attr_accessor :skip_otp

    # Links
    belongs_to :item_recipient, class_name: 'Aven::ItemRecipient', optional: true
    belongs_to :workspace, class_name: 'Aven::Workspace'
    belongs_to :recipient_workspace, class_name: 'Aven::Workspace', optional: true

    # Polymorphic relationships (app defines User/SystemUser models)
    belongs_to :inviter, polymorphic: true, optional: true
    belongs_to :invitee, polymorphic: true, optional: true

    # Delegation
    belongs_to :delegated_from_invite, class_name: 'Aven::Invite', optional: true
    has_many :delegated_invites, class_name: 'Aven::Invite', foreign_key: :delegated_from_invite_id, dependent: :nullify

    # Validations
    validates :invite_type, presence: true, inclusion: { in: Aven::InviteType::ALL }
    validates :invitee_email, presence: true
    validates :auth_link_hash, presence: true, uniqueness: true
    validates :completion_state, presence: true

    # OTP Verification
    def otp_verified?
      otp_verified_at.present?
    end

    def otp_pending?
      otp_sent_at.present? && !otp_verified?
    end

    def verify_otp!
      update!(otp_verified_at: Time.current)
    end

    def expired?
      expires_at.present? && expires_at < Time.current
    end

    # Delegation
    def can_delegate?
      allow_delegate && delegated_invites.count < 3 # Limit delegation depth
    end

    # State transitions
    def transition_to!(new_state)
      update!(completion_state: new_state)
    end

    def can_set_state_to?(new_state)
      # Basic state validation - apps can override
      valid_states = %w[pending verification_initiated verification_error verification_confirmed
                        completed delegation_prompt workspace_pending members_pending delegated]
      valid_states.include?(new_state)
    end
  end
end
