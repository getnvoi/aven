# frozen_string_literal: true

module Aven
  module System
    class ContactsController < BaseController
      def index
        @contacts = Aven::Item.by_schema("contact").active.includes(:workspace).order(created_at: :desc)

        # Apply filters
        if params[:q].present?
          @contacts = @contacts.where("data->>'display_name' ILIKE ?", "%#{params[:q]}%")
        end

        if params[:gender].present?
          @contacts = @contacts.where("data->>'gender' = ?", params[:gender])
        end

        @contacts = @contacts.limit(100)

        view_component("system/contacts/index", contacts: @contacts)
      end
    end
  end
end
