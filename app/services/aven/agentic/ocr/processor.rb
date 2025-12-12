# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class Processor
        class << self
          # Process a document and extract text content
          # @param document [Aven::Agentic::Document]
          # @return [String, nil] Extracted text content
          def process(document)
            extractor = extractor_for(document)
            return nil unless extractor

            extractor.extract(document)
          end

          private

            def extractor_for(document)
              case
              when document.pdf?
                PdfExtractor
              when document.image?
                ImageExtractor
              when document.word_doc?
                WordExtractor
              when document.excel?
                ExcelExtractor
              end
            end
        end
      end
    end
  end
end
