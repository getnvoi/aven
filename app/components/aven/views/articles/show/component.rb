# frozen_string_literal: true

module Aven::Views::Articles::Show
  class Component < Aven::ApplicationViewComponent
    option :article
    option :current_user, optional: true

    private

      def routes
        Aven::Engine.routes.url_helpers
      end

      def status_badge
        if article.published?
          { label: "Published", variant: :success }
        elsif article.scheduled?
          { label: "Scheduled", variant: :warning }
        else
          { label: "Draft", variant: :secondary }
        end
      end

      def format_date(date)
        return nil unless date
        date.strftime("%B %d, %Y at %l:%M %p")
      end

      def rendered_description
        # Simple markdown rendering - could use a proper markdown renderer
        simple_format(article.description)
      end
  end
end
