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
module Aven
  class Log < ApplicationRecord
    self.table_name = "aven_logs"

    LEVELS = %w[debug info warn error fatal].freeze

    belongs_to :loggable, polymorphic: true
    belongs_to :workspace, class_name: "Aven::Workspace"

    validates :message, presence: true
    validates :level, inclusion: { in: LEVELS }

    scope :by_level, ->(level) { where(level:) }
    scope :recent, -> { order(created_at: :desc) }

    before_validation :apply_loggable_context

    private

      def apply_loggable_context
        owner = loggable
        return unless owner

        if respond_to?(:workspace_id) && workspace_id.blank?
          if owner.is_a?(Aven::Workspace)
            self.workspace = owner
          elsif owner.respond_to?(:workspace)
            self.workspace = owner.workspace
          end
        end

        if respond_to?(:run_id) && run_id.blank? && owner.respond_to?(:_log_run_id)
          self.run_id = owner._log_run_id
        end
      end
  end
end

