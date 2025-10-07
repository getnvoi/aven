module Sqema
  class WorkspaceRole < ApplicationRecord
    self.table_name = "sqema_workspace_roles"

    belongs_to :workspace, class_name: "Sqema::Workspace"
    has_many :workspace_user_roles, class_name: "Sqema::WorkspaceUserRole", dependent: :destroy
    has_many :workspace_users, through: :workspace_user_roles, class_name: "Sqema::WorkspaceUser"
    has_many :users, through: :workspace_users, class_name: "Sqema::User"

    validates :label, presence: true
    validates :label, uniqueness: { scope: :workspace_id }

    PREDEFINED_ROLES = %w[owner admin member viewer].freeze

    scope :predefined, -> { where(label: PREDEFINED_ROLES) }
    scope :custom, -> { where.not(label: PREDEFINED_ROLES) }

    def predefined?
      PREDEFINED_ROLES.include?(label)
    end

    def custom?
      !predefined?
    end
  end
end

