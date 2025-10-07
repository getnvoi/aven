module Sqema
  class Workspace < ApplicationRecord
    self.table_name = "sqema_workspaces"

    has_many :workspace_users, class_name: "Sqema::WorkspaceUser", dependent: :destroy
    has_many :users, through: :workspace_users, class_name: "Sqema::User"
    has_many :workspace_roles, class_name: "Sqema::WorkspaceRole", dependent: :destroy
    has_many :workspace_user_roles, through: :workspace_roles, class_name: "Sqema::WorkspaceUserRole"

    validates :slug, uniqueness: true, allow_blank: true
    validates :label, length: { maximum: 255 }, allow_blank: true
    validates :description, length: { maximum: 1000 }, allow_blank: true

    before_validation :generate_slug, if: -> { slug.blank? && label.present? }

    private

      def generate_slug
        self.slug = label.parameterize if label.present?
      end
  end
end

