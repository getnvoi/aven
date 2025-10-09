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
FactoryBot.define do
  factory :aven_app_record_schema, class: "Aven::AppRecordSchema" do
    association :workspace, factory: :aven_workspace
    schema { { "type" => "object", "properties" => { "name" => { "type" => "string" } } } }
  end
end

