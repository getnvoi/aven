# == Schema Information
#
# Table name: aven_workspace_users
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  idx_aven_workspace_users_on_user_workspace  (user_id,workspace_id) UNIQUE
#  index_aven_workspace_users_on_user_id       (user_id)
#  index_aven_workspace_users_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
FactoryBot.define do
  factory :aven_workspace_user, class: "Aven::WorkspaceUser" do
    association :user, factory: :aven_user
    association :workspace, factory: :aven_workspace
  end
end
