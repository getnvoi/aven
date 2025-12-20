# frozen_string_literal: true

module Aven
  class ApplicationMailer < ActionMailer::Base
    default from: -> { default_from_address }
    layout "mailer"

    private

      def default_from_address
        Aven.configuration.mailer_from_address || "noreply@example.com"
      end
  end
end
