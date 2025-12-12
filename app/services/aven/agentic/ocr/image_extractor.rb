# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class ImageExtractor < BaseExtractor
        class << self
          def extract(document)
            with_tempfile(document) do |path|
              if Aven.configuration.ocr&.provider == :textract
                TextractClient.extract_document(path)
              else
                Rails.logger.warn("[Aven::OCR] No OCR provider configured for images")
                nil
              end
            end
          end
        end
      end
    end
  end
end
