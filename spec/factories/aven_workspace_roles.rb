# == Schema Information
#
# Table name: aven_workspace_roles
#
#  id           :bigint           not null, primary key
#  description  :string
#  label        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint
#
# Indexes
#
#  idx_aven_workspace_roles_on_ws_label        (workspace_id,label) UNIQUE
#  index_aven_workspace_roles_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
FactoryBot.define do
  factory :aven_workspace_role, class: "Aven::WorkspaceRole" do
    association :workspace, factory: :aven_workspace
    sequence(:label) { |n| "role_#{n}" }
    description { "A role" }
  end
end
