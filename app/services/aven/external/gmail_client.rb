# frozen_string_literal: true

module Aven
  module External
    class GmailClient
      class Error < StandardError; end

      GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1"
      PAGE_SIZE = 100

      IGNORED_PATTERNS = %w[
        noreply no-reply notifications notification
        mailer-daemon postmaster bounce
        newsletter news updates update
        support help info contact
        donotreply do-not-reply
      ].freeze

      def initialize(access_token, exclude_emails: [])
        @access_token = access_token
        @exclude_emails = Array(exclude_emails).map(&:downcase)
        @connection = build_connection
      end

      # Scan emails and extract unique addresses
      # Returns { emails_scanned: N, addresses: [{ email:, name:, domain: }, ...] }
      def extract_email_addresses(max_emails: 2000, &progress_callback)
        addresses = {}
        emails_scanned = 0
        page_token = nil

        loop do
          break if emails_scanned >= max_emails

          messages_response = fetch_messages(
            page_token:,
            max_results: [PAGE_SIZE, max_emails - emails_scanned].min
          )
          messages = messages_response["messages"] || []

          break if messages.empty?

          messages.each do |msg|
            break if emails_scanned >= max_emails

            begin
              message = fetch_message(msg["id"])
              extract_addresses_from_message(message, addresses)
              emails_scanned += 1
              progress_callback&.call(emails_scanned)
            rescue StandardError => e
              Rails.logger.warn("Failed to fetch message #{msg['id']}: #{e.message}")
            end
          end

          page_token = messages_response["nextPageToken"]
          break unless page_token
        end

        {
          emails_scanned:,
          addresses: addresses.values
        }
      end

      # Extract addresses and create import entries
      def fetch_into_import(import, max_emails: 2000, &progress_callback)
        result = extract_email_addresses(max_emails:, &progress_callback)

        result[:addresses].each do |address_data|
          import.entries.create!(data: address_data)
        end

        result
      end

      private

        def build_connection
          Faraday.new(GMAIL_API_BASE) do |f|
            f.request :json
            f.response :json
            f.adapter Faraday.default_adapter
          end
        end

        def fetch_messages(page_token: nil, max_results: PAGE_SIZE)
          params = { maxResults: max_results }
          params[:pageToken] = page_token if page_token

          response = @connection.get("users/me/messages", params) do |req|
            req.headers["Authorization"] = "Bearer #{@access_token}"
          end

          raise Error, "Gmail API error: #{response.body}" unless response.success?

          response.body
        end

        def fetch_message(message_id)
          response = @connection.get("users/me/messages/#{message_id}", { format: "metadata" }) do |req|
            req.headers["Authorization"] = "Bearer #{@access_token}"
          end

          raise Error, "Gmail API error: #{response.body}" unless response.success?

          response.body
        end

        def extract_addresses_from_message(message, addresses)
          headers = message.dig("payload", "headers") || []

          %w[From To Cc].each do |header_name|
            header = headers.find { |h| h["name"] == header_name }
            next unless header

            parse_email_header(header["value"]).each do |parsed|
              next if ignored_address?(parsed[:email])
              next if addresses.key?(parsed[:email].downcase)

              addresses[parsed[:email].downcase] = {
                "email" => parsed[:email],
                "name" => parsed[:name],
                "domain" => parsed[:email].split("@").last
              }
            end
          end
        end

        def parse_email_header(header_value)
          return [] if header_value.blank?

          results = []
          parts = header_value.scan(/(?:"[^"]*"|[^,])+/).map(&:strip).reject(&:blank?)

          parts.each do |part|
            if part =~ /^(?:"?(.+?)"?\s+)?<([^>]+@[^>]+)>$/
              name = ::Regexp.last_match(1)&.strip
              email = ::Regexp.last_match(2)&.strip&.downcase
            elsif part =~ /^([a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})$/
              name = nil
              email = ::Regexp.last_match(1)&.strip&.downcase
            else
              next
            end

            next unless email
            next unless email.include?("@")
            next if email.length < 5

            results << { name: name.presence, email: }
          end

          results
        end

        def ignored_address?(email)
          return true if email.blank?

          local_part = email.split("@").first&.downcase || ""
          domain = email.split("@").last&.downcase || ""

          return true if @exclude_emails.include?(email.downcase)
          return true if local_part.match?(/^(no[-_]?reply|noreply|do[-_]?not[-_]?reply|mailer[-_]?daemon|postmaster|bounce|daemon)/i)
          return true if IGNORED_PATTERNS.any? { |keyword| local_part.include?(keyword) }
          return true if domain == "noreply.github.com"
          return true if domain.match?(/(^|\.)(substack\.com|beehiiv\.com|medium\.com)$/i)

          false
        end
    end
  end
end
