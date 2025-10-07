module Sqema
  class Log < ApplicationRecord
    self.table_name = "sqema_logs"

    LEVELS = %w[debug info warn error fatal].freeze

    belongs_to :loggable, polymorphic: true
    belongs_to :workspace, class_name: "Sqema::Workspace"

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
          if owner.is_a?(Sqema::Workspace)
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

