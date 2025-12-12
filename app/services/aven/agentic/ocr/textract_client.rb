# frozen_string_literal: true

module Aven
  module Agentic
    module Ocr
      class TextractClient
        class << self
          # Extract text from document using AWS Textract
          # @param file_path [String] Path to the file
          # @return [String, nil] Extracted text
          def extract_document(file_path)
            client = build_client
            return nil unless client

            bytes = File.binread(file_path)

            response = client.detect_document_text(
              document: { bytes: }
            )

            extract_text_from_response(response)
          rescue Aws::Textract::Errors::ServiceError => e
            Rails.logger.error("[Aven::Textract] API error: #{e.message}")
            nil
          end

          # Extract text from multi-page document (async)
          # @param s3_bucket [String] S3 bucket name
          # @param s3_key [String] S3 object key
          # @return [String, nil] Extracted text
          def extract_document_async(s3_bucket:, s3_key:)
            client = build_client
            return nil unless client

            # Start async job
            start_response = client.start_document_text_detection(
              document_location: {
                s3_object: {
                  bucket: s3_bucket,
                  name: s3_key
                }
              }
            )

            job_id = start_response.job_id
            wait_for_job(client, job_id)
          rescue Aws::Textract::Errors::ServiceError => e
            Rails.logger.error("[Aven::Textract] Async API error: #{e.message}")
            nil
          end

          private

            def build_client
              return nil unless defined?(Aws::Textract::Client)

              config = Aven.configuration.ocr
              return nil unless config&.aws_region

              Aws::Textract::Client.new(
                region: config.aws_region,
                credentials: aws_credentials(config)
              )
            end

            def aws_credentials(config)
              if config.aws_access_key_id && config.aws_secret_access_key
                Aws::Credentials.new(
                  config.aws_access_key_id,
                  config.aws_secret_access_key
                )
              else
                # Use default credential chain
                nil
              end
            end

            def extract_text_from_response(response)
              lines = response.blocks
                .select { |b| b.block_type == "LINE" }
                .sort_by { |b| [b.geometry.bounding_box.top, b.geometry.bounding_box.left] }
                .map(&:text)

              lines.join("\n")
            end

            def wait_for_job(client, job_id, max_attempts: 30, delay: 5)
              attempts = 0

              loop do
                response = client.get_document_text_detection(job_id:)

                case response.job_status
                when "SUCCEEDED"
                  return collect_all_pages(client, job_id)
                when "FAILED"
                  Rails.logger.error("[Aven::Textract] Job failed: #{response.status_message}")
                  return nil
                when "IN_PROGRESS"
                  attempts += 1
                  if attempts >= max_attempts
                    Rails.logger.error("[Aven::Textract] Job timed out")
                    return nil
                  end
                  sleep(delay)
                end
              end
            end

            def collect_all_pages(client, job_id)
              all_text = []
              next_token = nil

              loop do
                params = { job_id: }
                params[:next_token] = next_token if next_token

                response = client.get_document_text_detection(params)
                all_text << extract_text_from_response(response)

                next_token = response.next_token
                break unless next_token
              end

              all_text.join("\n\n")
            end
        end
      end
    end
  end
end
