# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_item_schemas
#
#  id           :bigint           not null, primary key
#  embeds       :jsonb            not null
#  fields       :jsonb            not null
#  links        :jsonb            not null
#  schema       :jsonb            not null
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_item_schemas_on_slug                   (slug)
#  index_aven_item_schemas_on_workspace_id           (workspace_id)
#  index_aven_item_schemas_on_workspace_id_and_slug  (workspace_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class ItemSchema < ApplicationRecord
    self.table_name = "aven_item_schemas"

    include Aven::Model::TenantModel
    include Aven::Loggable

    has_many :items, ->(schema) { where(schema_slug: schema.slug) },
             class_name: "Aven::Item",
             foreign_key: false,
             inverse_of: false

    validates :slug, presence: true,
                     uniqueness: { scope: :workspace_id },
                     format: { with: /\A[a-z][a-z0-9_]*\z/, message: "must be lowercase, start with letter, contain only letters/numbers/underscores" }
    validates :schema, presence: true
    validate :validate_schema_format

    # Mimic the interface of code-defined schemas (Item::Schemas::Base)
    def builder
      self
    end

    def to_json_schema
      schema
    end

    # Accessors that match Item::Schemas::Base interface
    def fields_config
      (fields || {}).deep_symbolize_keys
    end

    def embeds_config
      (embeds || {}).deep_symbolize_keys
    end

    def links_config
      (links || {}).deep_symbolize_keys
    end

    # Alias methods to match Schemas::Base
    alias_method :schema_fields, :fields_config
    alias_method :schema_embeds, :embeds_config
    alias_method :schema_links, :links_config

    private

      def validate_schema_format
        return if schema.blank?

        unless schema.is_a?(Hash)
          errors.add(:schema, "must be a valid JSON object")
          return
        end

        unless schema["type"].present?
          errors.add(:schema, "must include a 'type' property")
        end
      end
  end
end
