# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class WordExtractor < BaseExtractor
        class << self
          def extract(document)
            with_tempfile(document) do |path|
              extract_docx(path)
            end
          end

          private

            def extract_docx(path)
              # Use docx gem if available
              if defined?(Docx::Document)
                doc = Docx::Document.open(path)
                paragraphs = doc.paragraphs.map(&:text)
                paragraphs.join("\n\n")
              else
                Rails.logger.warn("[Aven::OCR] docx gem not available")
                nil
              end
            rescue => e
              Rails.logger.error("[Aven::OCR] Word extraction failed: #{e.message}")
              nil
            end
        end
      end
    end
  end
end
