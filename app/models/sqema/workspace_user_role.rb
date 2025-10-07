module Sqema
  class WorkspaceUserRole < ApplicationRecord
    self.table_name = "sqema_workspace_user_roles"

    belongs_to :workspace_user, class_name: "Sqema::WorkspaceUser"
    belongs_to :workspace_role, class_name: "Sqema::WorkspaceRole"

    validates :workspace_user_id, uniqueness: { scope: :workspace_role_id }

    delegate :workspace, :label, :description, to: :workspace_role
    delegate :user, to: :workspace_user
    delegate :email, :username, to: :user

    scope :for_workspace, ->(workspace) { joins(:workspace_role).where(sqema_workspace_roles: { workspace_id: workspace.id }) }
    scope :with_role, ->(role_label) { joins(:workspace_role).where(sqema_workspace_roles: { label: role_label }) }
  end
end

