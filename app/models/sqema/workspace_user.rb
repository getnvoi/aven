module Sqema
  class WorkspaceUser < ApplicationRecord
    self.table_name = "sqema_workspace_users"

    belongs_to :user, class_name: "Sqema::User"
    belongs_to :workspace, class_name: "Sqema::Workspace"

    has_many :workspace_user_roles, class_name: "Sqema::WorkspaceUserRole", dependent: :destroy
    has_many :workspace_roles, through: :workspace_user_roles, class_name: "Sqema::WorkspaceRole"

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

