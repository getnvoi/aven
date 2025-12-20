# frozen_string_literal: true

module Aven
  module System
    class FeaturesController < BaseController
      def index
        @features = Aven::Feature.active.includes(:feature_tools)

        # Apply search
        @features = params[:q].present? ? @features.search(params[:q]) : @features.order(created_at: :desc)

        # Apply filters
        @features = @features.where(feature_type: params[:feature_type]) if params[:feature_type].present?

        # Paginate
        @features = @features.page(params[:page]).per(params[:per_page] || 25)

        view_component("system/features/index", features: @features)
      end

      def show
        @feature = Aven::Feature.find(params[:id])
        view_component("system/features/show", feature: @feature)
      end

      def edit
        @feature = Aven::Feature.find(params[:id])
        view_component("system/features/edit", feature: @feature)
      end

      def update
        @feature = Aven::Feature.find(params[:id])
        if @feature.update(feature_params)
          redirect_to aven.system_features_path, notice: "Feature updated successfully."
        else
          view_component("system/features/edit", feature: @feature, status: :unprocessable_entity)
        end
      end

      private

      def feature_params
        params.require(:feature).permit(:name, :editorial_title, :editorial_description, :editorial_body, :auto_activate, :feature_type)
      end
    end
  end
end
