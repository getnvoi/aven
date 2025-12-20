# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_feature_tools
#
#  id          :bigint           not null, primary key
#  config      :jsonb
#  deleted_at  :datetime
#  description :text
#  slug        :string           not null
#  title       :string           not null
#  tool_type   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  feature_id  :bigint           not null
#  schema_id   :bigint
#
# Indexes
#
#  index_aven_feature_tools_on_deleted_at           (deleted_at)
#  index_aven_feature_tools_on_feature_id           (feature_id)
#  index_aven_feature_tools_on_schema_id            (schema_id)
#  index_aven_feature_tools_on_slug_and_feature_id  (slug,feature_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (feature_id => aven_features.id)
#
module Aven
  class FeatureTool < ApplicationRecord
    self.table_name = 'aven_feature_tools'

    VALID_TYPES = %w[producer core knowledge system].freeze

    belongs_to :feature, class_name: 'Aven::Feature'

    has_many :feature_tool_usages, class_name: 'Aven::FeatureToolUsage', dependent: :destroy

    validates :title, presence: true
    validates :slug, presence: true, uniqueness: { scope: :feature_id }
    validates :tool_type, inclusion: { in: VALID_TYPES }, allow_nil: true

    before_validation :generate_slug, if: -> { title.present? && slug.blank? }

    scope :active, -> { where(deleted_at: nil) }
    scope :archived, -> { where.not(deleted_at: nil) }

    def archive
      update(deleted_at: Time.current)
    end

    def archived?
      deleted_at.present?
    end

    private

    def generate_slug
      self.slug = title.to_s.downcase.strip.gsub(/\s+/, "-").gsub(/[^\w-]/, "").gsub(/-+/, "-")
    end
  end
end
