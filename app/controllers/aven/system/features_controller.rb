# frozen_string_literal: true

module Aven
  module System
    class FeaturesController < BaseController
      def index
        @features = Aven::Feature.active.includes(:feature_tools).order(created_at: :desc)

        # Apply filters
        if params[:q].present?
          @features = @features.where("name ILIKE ? OR slug ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
        end

        if params[:feature_type].present?
          @features = @features.where(feature_type: params[:feature_type])
        end

        @features = @features.limit(100)

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
