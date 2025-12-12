# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_items
#
#  id           :bigint           not null, primary key
#  data         :jsonb            not null
#  deleted_at   :datetime
#  schema_slug  :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_items_on_data          (data) USING gin
#  index_aven_items_on_deleted_at    (deleted_at)
#  index_aven_items_on_schema_slug   (schema_slug)
#  index_aven_items_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class Item < ApplicationRecord
    include Aven::Model::TenantModel
    include Aven::Loggable
    include Item::Schemaed
    include Item::Embeddable
    include Item::Linkable

    self.table_name = "aven_items"

    validates :schema_slug, presence: true
    validates :data, presence: true

    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
    scope :by_schema, ->(slug) { where(schema_slug: slug) }
    scope :recent, -> { order(created_at: :desc) }

    def soft_delete!
      update!(deleted_at: Time.current)
    end

    def restore!
      update!(deleted_at: nil)
    end

    def deleted?
      deleted_at.present?
    end

    class << self
      def schema_class_for(slug)
        "Aven::Item::Schemas::#{slug.to_s.camelize}".constantize
      rescue NameError
        nil
      end

      def schema_for(slug)
        schema_class_for(slug)&.builder
      end
    end

    def schema_class
      self.class.schema_class_for(schema_slug)
    end

    def schema_builder
      schema_class&.builder
    end
  end
end
