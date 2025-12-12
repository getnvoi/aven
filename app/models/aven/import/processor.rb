# frozen_string_literal: true

module Aven
  class Import::Processor
    attr_reader :import

    def initialize(import)
      @import = import
    end

    def run
      import.mark_processing!

      import.entries.unlinked.find_each do |entry|
        process_entry(entry)
        import.increment_processed!
      end

      import.mark_completed!
    rescue StandardError => e
      import.mark_failed!(e.message)
      raise
    end

    private

      def process_entry(entry)
        return skip_entry(entry, "No email found") if entry_email(entry).blank?
        return skip_duplicate(entry) if duplicate?(entry)

        item = create_item(entry)
        entry.link_to_item!(item)
        import.increment_imported!
      rescue ActiveRecord::RecordInvalid => e
        import.increment_skipped!
        import.log_error("Failed to create item for entry #{entry.id}: #{e.message}")
      end

      def entry_email(entry)
        entry.data["email"]
      end

      def duplicate?(entry)
        email = entry_email(entry)
        Aven::Item.by_schema(target_schema)
                  .where(workspace_id: import.workspace_id)
                  .where("data->>'email' = ?", email)
                  .exists?
      end

      def skip_entry(entry, reason)
        import.increment_skipped!
        import.log_error("Skipped entry #{entry.id}: #{reason}")
      end

      def skip_duplicate(entry)
        import.increment_skipped!
        import.log_error("Duplicate email: #{entry_email(entry)}")
      end

      def create_item(entry)
        Aven::Item.create!(
          workspace_id: import.workspace_id,
          schema_slug: target_schema,
          data: build_item_data(entry)
        )
      end

      def target_schema
        case import.source
        when "google_contacts", "gmail_emails"
          "contact"
        else
          raise "Unknown source: #{import.source}"
        end
      end

      def build_item_data(entry)
        case import.source
        when "google_contacts"
          build_google_contact_data(entry.data)
        when "gmail_emails"
          build_gmail_email_data(entry.data)
        else
          entry.data
        end
      end

      def build_google_contact_data(data)
        {
          "first_name" => data["first_name"].presence || "Unknown",
          "last_name" => data["last_name"],
          "email" => data["email"],
          "phone" => data["phone"]
        }.compact
      end

      def build_gmail_email_data(data)
        first_name, last_name = parse_name(data["name"], data["email"])

        {
          "first_name" => first_name,
          "last_name" => last_name,
          "email" => data["email"]
        }.compact
      end

      def parse_name(name, email)
        if name.present?
          parts = name.split(/\s+/, 2)
          [parts[0], parts[1] || "Contact"]
        else
          local = email.to_s.split("@").first.to_s
          parts = local.split(/[._-]/)
          if parts.length >= 2
            [parts[0].titleize, parts[1..].join(" ").titleize]
          else
            [local.titleize, "Contact"]
          end
        end
      end
  end
end
