# == Schema Information
#
# Table name: aven_workspace_roles
#
#  id           :bigint           not null, primary key
#  description  :string
#  label        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint
#
# Indexes
#
#  idx_aven_workspace_roles_on_ws_label        (workspace_id,label) UNIQUE
#  index_aven_workspace_roles_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class WorkspaceRole < ApplicationRecord
    self.table_name = "aven_workspace_roles"

    belongs_to :workspace, class_name: "Aven::Workspace"
    has_many :workspace_user_roles, class_name: "Aven::WorkspaceUserRole", dependent: :destroy
    has_many :workspace_users, through: :workspace_user_roles, class_name: "Aven::WorkspaceUser"
    has_many :users, through: :workspace_users, class_name: "Aven::User"

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
