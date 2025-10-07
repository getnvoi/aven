FactoryBot.define do
  factory :sqema_log, class: "Sqema::Log" do
    level { "info" }
    message { "test message" }
    association :workspace, factory: :sqema_workspace
    association :loggable, factory: :sqema_workspace
    loggable_type { "Sqema::Workspace" }
    loggable_id { loggable.id }
  end
end

