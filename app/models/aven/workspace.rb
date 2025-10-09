# == Schema Information
#
# Table name: aven_workspaces
#
#  id          :bigint           not null, primary key
#  description :text
#  domain      :string
#  label       :string
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_aven_workspaces_on_slug  (slug) UNIQUE
#
module Aven
  class Workspace < ApplicationRecord
    self.table_name = "aven_workspaces"

    has_many :workspace_users, class_name: "Aven::WorkspaceUser", dependent: :destroy
    has_many :users, through: :workspace_users, class_name: "Aven::User"
    has_many :workspace_roles, class_name: "Aven::WorkspaceRole", dependent: :destroy
    has_many :workspace_user_roles, through: :workspace_roles, class_name: "Aven::WorkspaceUserRole"

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

