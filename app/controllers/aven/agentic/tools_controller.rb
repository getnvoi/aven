# frozen_string_literal: true

module Aven
  module Agentic
    class ToolsController < Aven::ApplicationController
      before_action :authenticate_user!
      before_action :set_tool, only: [:show, :update]

      def index
        @tools = Aven::Agentic::Tool.for_workspace(current_workspace).enabled.order(:name)
        render json: @tools.as_json(include: :parameters)
      end

      def show
        render json: @tool.as_json(include: :parameters)
      end

      def update
        if @tool.update(tool_params)
          render json: @tool
        else
          render json: { errors: @tool.errors }, status: :unprocessable_entity
        end
      end

      private

        def set_tool
          @tool = Aven::Agentic::Tool.for_workspace(current_workspace).find(params[:id])
        end

        def tool_params
          params.require(:tool).permit(:description, :enabled)
        end
    end
  end
end
