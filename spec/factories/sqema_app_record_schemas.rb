FactoryBot.define do
  factory :sqema_app_record_schema, class: "Sqema::AppRecordSchema" do
    association :workspace, factory: :sqema_workspace
    schema { { "type" => "object", "properties" => { "name" => { "type" => "string" } } } }
  end
end

