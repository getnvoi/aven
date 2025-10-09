module Aven
  module Admin
    class DashboardController < Base
      def index
        view_component("admin/dashboard/index", current_user:)
      end
    end
  end
end
