# frozen_string_literal: true

module Aven
  module Agentic
    class DocumentEmbeddingJob < Aven::ApplicationJob
      queue_as :default

      def perform(document_id)
        document = Aven::Agentic::Document.find_by(id: document_id)
        return unless document
        return unless document.embedding_status == "pending"
        return unless document.ocr_content.present?

        document.mark_embedding_processing!

        # Generate embeddings for document chunks
        document.generate_embeddings!

        # TODO: Call embedding API to fill in vector embeddings
        # For now, just mark as completed without actual embeddings
        document.mark_embedding_completed!
      rescue => e
        Rails.logger.error("[Aven::Embedding] Job failed for document #{document_id}: #{e.message}")
        document&.mark_embedding_failed!(e.message)
      end
    end
  end
end
