# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_features
#
#  id                    :bigint           not null, primary key
#  auto_activate         :boolean          default(FALSE), not null
#  config                :jsonb
#  deleted_at            :datetime
#  description           :text
#  editorial_body        :text
#  editorial_description :text
#  editorial_title       :string
#  feature_type          :string           default("boolean"), not null
#  metadata              :jsonb
#  name                  :string           not null
#  slug                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_aven_features_on_deleted_at    (deleted_at)
#  index_aven_features_on_feature_type  (feature_type)
#  index_aven_features_on_slug          (slug) UNIQUE
#
module Aven
  class Feature < ApplicationRecord
    include PgSearch::Model

    self.table_name = 'aven_features'

    # Tool/Access associations
    has_many :feature_tools, class_name: 'Aven::FeatureTool', dependent: :destroy
    has_many :feature_workspace_users, class_name: 'Aven::FeatureWorkspaceUser', dependent: :destroy

    validates :slug, presence: true, uniqueness: true
    validates :name, presence: true

    pg_search_scope :search,
      against: [:name, :slug, :editorial_title, :description],
      using: {
        tsearch: { prefix: true }
      }

    # Scopes for soft deletes
    scope :active, -> { where(deleted_at: nil) }
    scope :archived, -> { where.not(deleted_at: nil) }

    def archive
      update(deleted_at: Time.current)
    end

    def archived?
      deleted_at.present?
    end

    def active?
      deleted_at.nil?
    end
  end
end
