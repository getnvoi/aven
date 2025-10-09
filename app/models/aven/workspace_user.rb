# == Schema Information
#
# Table name: aven_workspace_users
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  idx_aven_workspace_users_on_user_workspace  (user_id,workspace_id) UNIQUE
#  index_aven_workspace_users_on_user_id       (user_id)
#  index_aven_workspace_users_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class WorkspaceUser < ApplicationRecord
    self.table_name = "aven_workspace_users"

    belongs_to :user, class_name: "Aven::User"
    belongs_to :workspace, class_name: "Aven::Workspace"

    has_many :workspace_user_roles, class_name: "Aven::WorkspaceUserRole", dependent: :destroy
    has_many :workspace_roles, through: :workspace_user_roles, class_name: "Aven::WorkspaceRole"

    validates :user_id, uniqueness: { scope: :workspace_id }

    def roles
      workspace_roles.pluck(:label)
    end

    def has_role?(role_label)
      workspace_roles.exists?(label: role_label)
    end

    def add_role(role_label)
      role = workspace.workspace_roles.find_or_create_by!(label: role_label)
      workspace_user_roles.find_or_create_by!(workspace_role: role)
    end

    def remove_role(role_label)
      role = workspace.workspace_roles.find_by(label: role_label)
      return unless role

      workspace_user_roles.where(workspace_role: role).destroy_all
    end
  end
end

