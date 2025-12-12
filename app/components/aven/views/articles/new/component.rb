# frozen_string_literal: true

module Aven::Views::Articles::New
  class Component < Aven::ApplicationViewComponent
    option :article
    option :current_user, optional: true

    private

      def routes
        Aven::Engine.routes.url_helpers
      end
  end
end
