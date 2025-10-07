FactoryBot.define do
  factory :sqema_workspace_user_role, class: "Sqema::WorkspaceUserRole" do
    association :workspace_user, factory: :sqema_workspace_user
    association :workspace_role, factory: :sqema_workspace_role
  end
end

