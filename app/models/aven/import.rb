# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_imports
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  error_message   :text
#  errors_log      :jsonb
#  imported_count  :integer          default(0)
#  processed_count :integer          default(0)
#  skipped_count   :integer          default(0)
#  source          :string           not null
#  started_at      :datetime
#  status          :string           default("pending"), not null
#  total_count     :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  workspace_id    :bigint           not null
#
# Indexes
#
#  index_aven_imports_on_source        (source)
#  index_aven_imports_on_status        (status)
#  index_aven_imports_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class Import < ApplicationRecord
    include Aven::Model::TenantModel

    self.table_name = "aven_imports"

    SOURCES = %w[google_contacts gmail_emails].freeze
    STATUSES = %w[pending fetching processing completed failed].freeze

    has_many :entries, class_name: "Aven::Import::Entry", dependent: :destroy

    validates :source, presence: true, inclusion: { in: SOURCES }
    validates :status, presence: true, inclusion: { in: STATUSES }

    scope :in_progress, -> { where(status: %w[pending fetching processing]) }
    scope :recent, -> { order(created_at: :desc) }
    scope :by_source, ->(source) { where(source: source) }

    def in_progress?
      %w[pending fetching processing].include?(status)
    end

    def completed?
      status == "completed"
    end

    def failed?
      status == "failed"
    end

    def progress_percentage
      return 0 if total_count.zero?
      (processed_count * 100.0 / total_count).round
    end

    def mark_fetching!(total: nil)
      attrs = { status: "fetching", started_at: Time.current }
      attrs[:total_count] = total if total
      update!(attrs)
    end

    def mark_processing!
      update!(status: "processing")
    end

    def increment_processed!
      increment!(:processed_count)
    end

    def increment_imported!
      increment!(:imported_count)
    end

    def increment_skipped!
      increment!(:skipped_count)
    end

    def mark_completed!
      update!(status: "completed", completed_at: Time.current)
    end

    def mark_failed!(message)
      update!(status: "failed", error_message: message, completed_at: Time.current)
    end

    def log_error(error)
      self.errors_log = (errors_log || []) << { at: Time.current.iso8601, message: error }
      save!
    end
  end
end
