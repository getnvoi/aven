# frozen_string_literal: true

module Aven::Views::Articles::Form
  class Component < Aven::ApplicationViewComponent
    option :article
    option :url
    option :current_user, optional: true

    private

      def routes
        Aven::Engine.routes.url_helpers
      end

      def existing_attachments
        article.sorted_attachments.select { |a| a.file.attached? }.map do |attachment|
          {
            id: attachment.id,
            position: attachment.position,
            signed_id: attachment.file.signed_id,
            url: helpers.url_for(attachment.file),
            filename: attachment.file.filename.to_s
          }
        end
      end
  end
end
