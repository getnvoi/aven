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
    validate :validate_data_against_schema

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

    # Schema resolution: code class first, then DB, then raise
    class << self
      def schema_class_for(slug)
        "Aven::Item::Schemas::#{slug.to_s.camelize}".constantize
      rescue NameError
        nil
      end

      def schema_for(slug, workspace: nil)
        # 1. Try code-defined class
        schema_class_for(slug) ||
        # 2. Try DB (requires workspace)
        (workspace && Aven::ItemSchema.find_by!(workspace:, slug:))
      end
    end

    def schema_class
      self.class.schema_class_for(schema_slug)
    end

    # Returns the schema source (code class or DB record)
    def resolved_schema
      @_resolved_schema ||= begin
        # 1. Code class first
        code_schema = self.class.schema_class_for(schema_slug)
        return code_schema if code_schema

        # 2. DB lookup (raises if not found)
        Aven::ItemSchema.find_by!(workspace:, slug: schema_slug)
      end
    end

    def schema_builder
      resolved_schema&.builder
    end

    private

      def validate_data_against_schema
        return if schema_slug.blank? || data.blank?

        begin
          json_schema = resolved_schema&.to_json_schema
          return if json_schema.blank?

          registry = JSONSkooma.create_registry("2020-12", assert_formats: true)
          schema_with_meta = json_schema.dup
          schema_with_meta["$schema"] ||= "https://json-schema.org/draft/2020-12/schema"
          validator = JSONSkooma::JSONSchema.new(schema_with_meta, registry:)
          result = validator.evaluate(data)

          unless result.valid?
            error_output = result.output(:basic)
            if error_output["errors"]
              error_messages = error_output["errors"].map do |err|
                location = err["instanceLocation"] || "data"
                message = err["error"] || "validation failed"
                "#{location}: #{message}"
              end
              errors.add(:data, "schema validation failed: #{error_messages.join('; ')}")
            else
              errors.add(:data, "does not conform to schema")
            end
          end
        rescue ActiveRecord::RecordNotFound
          errors.add(:schema_slug, "schema '#{schema_slug}' not found")
        rescue => e
          errors.add(:data, "schema validation error: #{e.message}")
        end
      end
  end
end
