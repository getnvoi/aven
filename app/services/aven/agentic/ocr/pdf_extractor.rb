# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class PdfExtractor < BaseExtractor
        class << self
          def extract(document)
            with_tempfile(document) do |path|
              # Try text extraction first (for text-based PDFs)
              text = extract_text_layer(path)
              return text if text.present?

              # Fall back to OCR for scanned PDFs
              extract_with_ocr(path)
            end
          end

          private

            def extract_text_layer(path)
              # Use pdf-reader gem if available
              if defined?(PDF::Reader)
                reader = PDF::Reader.new(path)
                text = reader.pages.map(&:text).join("\n\n")
                return text if text.strip.present?
              end

              nil
            rescue => e
              Rails.logger.warn("[Aven::OCR] PDF text extraction failed: #{e.message}")
              nil
            end

            def extract_with_ocr(path)
              # Use AWS Textract if configured
              if Aven.configuration.ocr&.provider == :textract
                TextractClient.extract_document(path)
              else
                Rails.logger.warn("[Aven::OCR] No OCR provider configured")
                nil
              end
            end
        end
      end
    end
  end
end
