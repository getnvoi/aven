# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_feature_workspace_users
#
#  id           :bigint           not null, primary key
#  config       :jsonb
#  enabled      :boolean          default(FALSE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  feature_id   :bigint           not null
#  user_id      :bigint           not null
#  workspace_id :bigint           not null
#
# Indexes
#
#  idx_aven_feature_workspace_users_unique             (workspace_id,user_id,feature_id) UNIQUE
#  index_aven_feature_workspace_users_on_feature_id    (feature_id)
#  index_aven_feature_workspace_users_on_user_id       (user_id)
#  index_aven_feature_workspace_users_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (feature_id => aven_features.id)
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class FeatureWorkspaceUser < ApplicationRecord
    self.table_name = 'aven_feature_workspace_users'

    belongs_to :workspace, class_name: 'Aven::Workspace'
    belongs_to :user, class_name: 'Aven::User'
    belongs_to :feature, class_name: 'Aven::Feature'

    validates :workspace_id, uniqueness: { scope: %i[user_id feature_id] }
  end
end
