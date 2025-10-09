# == Schema Information
#
# Table name: aven_app_records
#
#  id                   :bigint           not null, primary key
#  data                 :jsonb            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  app_record_schema_id :bigint           not null
#
# Indexes
#
#  index_aven_app_records_on_app_record_schema_id  (app_record_schema_id)
#  index_aven_app_records_on_data                  (data) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (app_record_schema_id => aven_app_record_schemas.id)
#
FactoryBot.define do
  factory :aven_app_record, class: "Aven::AppRecord" do
    association :app_record_schema, factory: :aven_app_record_schema
    data { { "name" => "Example" } }
  end
end

