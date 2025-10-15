# == Schema Information
#
# Table name: aven_workspace_user_roles
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  workspace_role_id :bigint
#  workspace_user_id :bigint
#
# Indexes
#
#  idx_aven_ws_user_roles_on_role_user                   (workspace_role_id,workspace_user_id) UNIQUE
#  index_aven_workspace_user_roles_on_workspace_role_id  (workspace_role_id)
#  index_aven_workspace_user_roles_on_workspace_user_id  (workspace_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_role_id => aven_workspace_roles.id)
#  fk_rails_...  (workspace_user_id => aven_workspace_users.id)
#
module Aven
  class WorkspaceUserRole < ApplicationRecord
    self.table_name = "aven_workspace_user_roles"

    belongs_to :workspace_user, class_name: "Aven::WorkspaceUser"
    belongs_to :workspace_role, class_name: "Aven::WorkspaceRole"

    validates :workspace_user_id, uniqueness: { scope: :workspace_role_id }

    delegate :workspace, :label, :description, to: :workspace_role
    delegate :user, to: :workspace_user
    delegate :email, :username, to: :user

    scope :for_workspace, ->(workspace) { joins(:workspace_role).where(aven_workspace_roles: { workspace_id: workspace.id }) }
    scope :with_role, ->(role_label) { joins(:workspace_role).where(aven_workspace_roles: { label: role_label }) }
  end
end
