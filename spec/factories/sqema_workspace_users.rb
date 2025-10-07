FactoryBot.define do
  factory :sqema_workspace_user, class: "Sqema::WorkspaceUser" do
    association :user, factory: :sqema_user
    association :workspace, factory: :sqema_workspace
  end
end

