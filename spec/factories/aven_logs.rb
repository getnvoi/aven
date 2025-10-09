# == Schema Information
#
# Table name: aven_logs
#
#  id            :bigint           not null, primary key
#  level         :string           default("info"), not null
#  loggable_type :string           not null
#  message       :text             not null
#  metadata      :jsonb
#  state         :string
#  state_machine :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  loggable_id   :bigint           not null
#  run_id        :string
#  workspace_id  :bigint           not null
#
# Indexes
#
#  idx_aven_logs_on_loggable_run_state_created_at  (loggable_type,loggable_id,run_id,state,created_at)
#  index_aven_logs_on_created_at                   (created_at)
#  index_aven_logs_on_level                        (level)
#  index_aven_logs_on_loggable                     (loggable_type,loggable_id)
#  index_aven_logs_on_workspace_id                 (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
FactoryBot.define do
  factory :aven_log, class: "Aven::Log" do
    level { "info" }
    message { "test message" }
    association :workspace, factory: :aven_workspace
    association :loggable, factory: :aven_workspace
    loggable_type { "Aven::Workspace" }
    loggable_id { loggable.id }
  end
end

