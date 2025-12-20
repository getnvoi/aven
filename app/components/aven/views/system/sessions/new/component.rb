# frozen_string_literal: true

module Aven::Views::System::Sessions::New
  class Component < Aven::ApplicationViewComponent
    option :email, optional: true
    option :alert, optional: true

    def form_path
      Aven::Engine.routes.url_helpers.system_login_path
    end
  end
end
