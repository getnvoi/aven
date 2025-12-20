# frozen_string_literal: true

module Aven
  module System
    class ContactsController < BaseController
      def index
        @contacts = Aven::Item.by_schema("contact").active.includes(:workspace)

        # Apply search
        @contacts = params[:q].present? ? @contacts.search(params[:q]) : @contacts.order(created_at: :desc)

        # Apply filters
        @contacts = @contacts.where("data->>'gender' = ?", params[:gender]) if params[:gender].present?

        # Paginate
        @contacts = @contacts.page(params[:page]).per(params[:per_page] || 25)

        view_component("system/contacts/index", contacts: @contacts)
      end
    end
  end
end
