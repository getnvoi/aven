# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_documents
#
#  id               :bigint           not null, primary key
#  byte_size        :bigint           not null
#  content_type     :string           not null
#  embedding_status :string           default("pending"), not null
#  filename         :string           not null
#  metadata         :jsonb
#  ocr_content      :text
#  ocr_status       :string           default("pending"), not null
#  processed_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  workspace_id     :bigint           not null
#
# Indexes
#
#  index_aven_agentic_documents_on_content_type      (content_type)
#  index_aven_agentic_documents_on_embedding_status  (embedding_status)
#  index_aven_agentic_documents_on_ocr_status        (ocr_status)
#  index_aven_agentic_documents_on_workspace_id      (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  module Agentic
    class Document < Aven::ApplicationRecord
      self.table_name = "aven_agentic_documents"

      include Aven::Model::TenantModel
      include Aven::Agentic::DocumentEmbeddable

      has_one_attached :file

      has_many :embeddings,
               class_name: "Aven::Agentic::DocumentEmbedding",
               foreign_key: :document_id,
               dependent: :destroy

      has_many :agent_documents,
               class_name: "Aven::Agentic::AgentDocument",
               foreign_key: :document_id,
               dependent: :destroy,
               inverse_of: :document

      has_many :agents, through: :agent_documents

      # Statuses
      OCR_STATUSES = %w[pending processing completed failed skipped].freeze
      EMBEDDING_STATUSES = %w[pending processing completed failed].freeze

      # Allowed file types
      ALLOWED_CONTENT_TYPES = [
        "application/pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp"
      ].freeze

      MAX_FILE_SIZE = 30.megabytes

      validates :filename, presence: true
      validates :content_type, presence: true, inclusion: { in: ALLOWED_CONTENT_TYPES }
      validates :byte_size, presence: true, numericality: { less_than_or_equal_to: MAX_FILE_SIZE }
      validates :ocr_status, inclusion: { in: OCR_STATUSES }
      validates :embedding_status, inclusion: { in: EMBEDDING_STATUSES }
      validate :file_attached

      after_create_commit :enqueue_ocr_job

      scope :recent, -> { order(created_at: :desc) }
      scope :by_type, ->(type) { where("content_type LIKE ?", "#{type}%") }
      scope :images, -> { where("content_type LIKE ?", "image/%") }
      scope :pdfs, -> { where(content_type: "application/pdf") }
      scope :with_ocr, -> { where(ocr_status: "completed").where.not(ocr_content: nil) }
      scope :pending_ocr, -> { where(ocr_status: "pending") }
      scope :pending_embedding, -> { where(embedding_status: "pending", ocr_status: "completed") }

      def image?
        content_type.start_with?("image/")
      end

      def pdf?
        content_type == "application/pdf"
      end

      def word_doc?
        content_type.include?("wordprocessingml")
      end

      def excel?
        content_type.include?("spreadsheetml")
      end

      def ocr_required?
        image? || pdf?
      end

      def mark_ocr_processing!
        update!(ocr_status: "processing")
      end

      def mark_ocr_completed!(content)
        update!(
          ocr_status: "completed",
          ocr_content: content,
          processed_at: Time.current
        )
        enqueue_embedding_job if content.present?
      end

      def mark_ocr_failed!(error = nil)
        update!(
          ocr_status: "failed",
          metadata: metadata.merge("ocr_error" => error)
        )
      end

      def mark_ocr_skipped!
        update!(ocr_status: "skipped")
      end

      def mark_embedding_processing!
        update!(embedding_status: "processing")
      end

      def mark_embedding_completed!
        update!(embedding_status: "completed")
      end

      def mark_embedding_failed!(error = nil)
        update!(
          embedding_status: "failed",
          metadata: metadata.merge("embedding_error" => error)
        )
      end

      private

        def file_attached
          errors.add(:file, "must be attached") unless file.attached?
        end

        def enqueue_ocr_job
          Aven::Agentic::DocumentOcrJob.perform_later(id) if ocr_required?
        end

        def enqueue_embedding_job
          Aven::Agentic::DocumentEmbeddingJob.perform_later(id)
        end
    end
  end
end
