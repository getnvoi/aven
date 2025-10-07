module Sqema
  class AppRecordSchema < ApplicationRecord
    self.table_name = "sqema_app_record_schemas"

    include Sqema::Loggable

    belongs_to :workspace, class_name: "Sqema::Workspace"
    has_many :app_records, class_name: "Sqema::AppRecord", dependent: :destroy
    has_many :logs, as: :loggable, class_name: "Sqema::Log", dependent: :destroy

    validates :schema, presence: true
    validate :validate_openapi_schema_format

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

