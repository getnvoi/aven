# == Schema Information
#
# Table name: aven_app_record_schemas
#
#  id           :bigint           not null, primary key
#  schema       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_app_record_schemas_on_schema        (schema) USING gin
#  index_aven_app_record_schemas_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class AppRecordSchema < ApplicationRecord
    self.table_name = "aven_app_record_schemas"

    include Aven::Loggable

    belongs_to(:workspace, class_name: "Aven::Workspace")
    has_many(:app_records, class_name: "Aven::AppRecord", dependent: :destroy)
    has_many(:logs, as: :loggable, class_name: "Aven::Log", dependent: :destroy)

    validates(:schema, presence: true)
    validate(:validate_openapi_schema_format)

    private

      def validate_openapi_schema_format
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

