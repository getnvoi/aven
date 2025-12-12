# frozen_string_literal: true

module Aven
  module Agentic
    class DocumentOcrJob < Aven::ApplicationJob
      queue_as :default

      def perform(document_id)
        document = Aven::Agentic::Document.find_by(id: document_id)
        return unless document
        return unless document.ocr_status == "pending"

        document.mark_ocr_processing!

        content = Aven::Agentic::Ocr::Processor.process(document)

        if content.present?
          document.mark_ocr_completed!(content)
        else
          document.mark_ocr_skipped!
        end
      rescue => e
        Rails.logger.error("[Aven::OCR] Job failed for document #{document_id}: #{e.message}")
        document&.mark_ocr_failed!(e.message)
      end
    end
  end
end
