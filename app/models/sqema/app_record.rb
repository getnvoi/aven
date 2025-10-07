module Sqema
  class AppRecord < ApplicationRecord
    self.table_name = "sqema_app_records"

    include Sqema::Loggable

    belongs_to :app_record_schema, class_name: "Sqema::AppRecordSchema"
    has_many :logs, as: :loggable, class_name: "Sqema::Log", dependent: :destroy

    delegate :workspace, to: :app_record_schema

    validates :data, presence: true
    validate :validate_data_against_schema

    private

      def validate_data_against_schema
        if app_record_schema.blank?
          errors.add(:app_record_schema, "must exist")
          return
        end

        if app_record_schema.schema.blank?
          errors.add(:app_record_schema, "schema must be present")
          return
        end

        if data.blank?
          errors.add(:data, :blank)
          return
        end

        begin
          registry = JSONSkooma.create_registry("2020-12", assert_formats: true)
          schema_with_meta = app_record_schema.schema.dup
          schema_with_meta["$schema"] ||= "https://json-schema.org/draft/2020-12/schema"
          json_schema = JSONSkooma::JSONSchema.new(schema_with_meta, registry: registry)
          result = json_schema.evaluate(data)
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
        rescue => e
          errors.add(:data, "schema validation error: #{e.message}")
        end
      end
  end
end
