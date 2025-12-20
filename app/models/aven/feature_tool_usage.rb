# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_feature_tool_usages
#
#  id               :bigint           not null, primary key
#  duration_ms      :integer
#  http_status_code :integer
#  metadata         :jsonb
#  status           :string           default("success"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  feature_tool_id  :bigint           not null
#  user_id          :bigint           not null
#  workspace_id     :bigint           not null
#
# Indexes
#
#  idx_aven_feature_tool_usages_billing               (workspace_id,feature_tool_id,created_at)
#  idx_aven_feature_tool_usages_time                  (created_at)
#  idx_aven_feature_tool_usages_tool_time             (feature_tool_id,created_at)
#  idx_aven_feature_tool_usages_user_time             (user_id,created_at)
#  idx_aven_feature_tool_usages_workspace_time        (workspace_id,created_at)
#  index_aven_feature_tool_usages_on_feature_tool_id  (feature_tool_id)
#  index_aven_feature_tool_usages_on_user_id          (user_id)
#  index_aven_feature_tool_usages_on_workspace_id     (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (feature_tool_id => aven_feature_tools.id)
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class FeatureToolUsage < ApplicationRecord
    self.table_name = 'aven_feature_tool_usages'

    STATUSES = %w[success error unauthorized].freeze

    belongs_to :workspace, class_name: 'Aven::Workspace'
    belongs_to :user, class_name: 'Aven::User'
    belongs_to :feature_tool, class_name: 'Aven::FeatureTool'

    validates :status, presence: true, inclusion: { in: STATUSES }

    scope :for_workspace, ->(workspace_id) { where(workspace_id: workspace_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :for_tool, ->(feature_tool_id) { where(feature_tool_id: feature_tool_id) }
    scope :successful, -> { where(status: "success") }
    scope :in_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  end
end
