# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class ExcelExtractor < BaseExtractor
        class << self
          def extract(document)
            with_tempfile(document) do |path|
              extract_xlsx(path)
            end
          end

          private

            def extract_xlsx(path)
              # Use roo gem if available
              if defined?(Roo::Spreadsheet)
                xlsx = Roo::Spreadsheet.open(path)
                sheets = []

                xlsx.sheets.each do |sheet_name|
                  sheet = xlsx.sheet(sheet_name)
                  rows = sheet.each.map do |row|
                    row.map { |cell| cell.to_s.strip }.join("\t")
                  end
                  sheets << "## #{sheet_name}\n\n#{rows.join("\n")}"
                end

                sheets.join("\n\n---\n\n")
              else
                Rails.logger.warn("[Aven::OCR] roo gem not available")
                nil
              end
            rescue => e
              Rails.logger.error("[Aven::OCR] Excel extraction failed: #{e.message}")
              nil
            end
        end
      end
    end
  end
end
