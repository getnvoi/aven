# frozen_string_literal: true

require "google/apis/people_v1"

module Aven
  module External
    class GoogleContactsClient
      class Error < StandardError; end

      PERSON_FIELDS = %w[
        names
        emailAddresses
        phoneNumbers
        organizations
        photos
      ].join(",").freeze

      PAGE_SIZE = 100

      def initialize(access_token)
        @service = Google::Apis::PeopleV1::PeopleServiceService.new
        @service.authorization = access_token
      end

      def contacts_count
        response = @service.list_person_connections(
          "people/me",
          person_fields: "metadata",
          page_size: 1
        )
        response.total_items || 0
      rescue Google::Apis::Error => e
        raise Error, "Google API error: #{e.message}"
      end

      def each_contact(&block)
        page_token = nil

        loop do
          response = @service.list_person_connections(
            "people/me",
            person_fields: PERSON_FIELDS,
            page_size: PAGE_SIZE,
            page_token:,
            sort_order: "LAST_MODIFIED_DESCENDING"
          )

          (response.connections || []).each do |person|
            yield normalize_contact(person)
          end

          page_token = response.next_page_token
          break unless page_token
        end
      rescue Google::Apis::Error => e
        raise Error, "Google API error: #{e.message}"
      end

      def fetch_all
        contacts = []
        each_contact { |c| contacts << c }
        contacts
      end

      # Fetch contacts and create import entries
      def fetch_into_import(import, &progress_callback)
        count = 0
        each_contact do |contact_data|
          import.entries.create!(data: contact_data)
          count += 1
          progress_callback&.call(count)
        end
        count
      end

      private

        def normalize_contact(person)
          name = person.names&.first
          emails = person.email_addresses || []
          phones = person.phone_numbers || []
          org = person.organizations&.first

          {
            "google_resource_name" => person.resource_name,
            "first_name" => name&.given_name,
            "last_name" => name&.family_name,
            "email" => emails.first&.value,
            "phone" => phones.first&.value,
            "company" => org&.name
          }.compact
        end
    end
  end
end
