# == Schema Information
#
# Table name: aven_workspace_user_roles
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  workspace_role_id :bigint
#  workspace_user_id :bigint
#
# Indexes
#
#  idx_aven_ws_user_roles_on_role_user                   (workspace_role_id,workspace_user_id) UNIQUE
#  index_aven_workspace_user_roles_on_workspace_role_id  (workspace_role_id)
#  index_aven_workspace_user_roles_on_workspace_user_id  (workspace_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_role_id => aven_workspace_roles.id)
#  fk_rails_...  (workspace_user_id => aven_workspace_users.id)
#
FactoryBot.define do
  factory :aven_workspace_user_role, class: "Aven::WorkspaceUserRole" do
    association :workspace_user, factory: :aven_workspace_user
    association :workspace_role, factory: :aven_workspace_role
  end
end
