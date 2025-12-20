# frozen_string_literal: true

module Aven::Views::Auth::MagicLinks::Verify
  class Component < Aven::ApplicationViewComponent
    option :code, optional: true
    option :notice, optional: true
    option :alert, optional: true
    option :magic_link_code, optional: true  # Development only

    def form_path
      Aven::Engine.routes.url_helpers.auth_consume_magic_link_path
    end

    def request_new_path
      Aven::Engine.routes.url_helpers.auth_magic_link_path
    end

    def show_dev_code?
      Rails.env.development? && magic_link_code.present?
    end
  end
end
