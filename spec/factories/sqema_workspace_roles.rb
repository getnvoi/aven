FactoryBot.define do
  factory :sqema_workspace_role, class: "Sqema::WorkspaceRole" do
    association :workspace, factory: :sqema_workspace
    sequence(:label) { |n| "role_#{n}" }
    description { "A role" }
  end
end

