FactoryBot.define do
  factory :sqema_app_record, class: "Sqema::AppRecord" do
    association :app_record_schema, factory: :sqema_app_record_schema
    data { { "name" => "Example" } }
  end
end

