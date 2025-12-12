# frozen_string_literal: true

module Aven::Views::Articles::Index
  class Component < Aven::ApplicationViewComponent
    option :articles
    option :current_user, optional: true

    private

      def routes
        Aven::Engine.routes.url_helpers
      end

      def status_badge(article)
        if article.published?
          { label: "Published", variant: :success }
        elsif article.scheduled?
          { label: "Scheduled", variant: :warning }
        else
          { label: "Draft", variant: :secondary }
        end
      end

      def format_date(date)
        return "—" unless date
        date.strftime("%b %d, %Y")
      end
  end
end
