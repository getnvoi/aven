# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class BaseExtractor
        class << self
          # Extract text from document
          # @param document [Aven::Agentic::Document]
          # @return [String, nil] Extracted text
          def extract(document)
            raise NotImplementedError, "#{name} must implement extract"
          end

          protected

            # Download file to temp location
            def with_tempfile(document, &block)
              return nil unless document.file.attached?

              extension = File.extname(document.filename)
              tempfile = Tempfile.new(["aven_ocr", extension])

              begin
                tempfile.binmode
                tempfile.write(document.file.download)
                tempfile.rewind

                yield tempfile.path
              ensure
                tempfile.close
                tempfile.unlink
              end
            end
        end
      end
    end
  end
end
