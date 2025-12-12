# frozen_string_literal: true

module Aven
  module Agentic
    class AgentsController < Aven::ApplicationController
      before_action :authenticate_user!
      before_action :set_agent, only: [:show, :update, :destroy]

      def index
        @agents = current_workspace.aven_agentic_agents.enabled.order(:label)
        render json: @agents
      end

      def show
        render json: @agent.as_json(include: [:tools, :documents])
      end

      def create
        @agent = current_workspace.aven_agentic_agents.build(agent_params)

        if @agent.save
          render json: @agent, status: :created
        else
          render json: { errors: @agent.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @agent.update(agent_params)
          render json: @agent
        else
          render json: { errors: @agent.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @agent.destroy
        head :no_content
      end

      private

        def set_agent
          @agent = current_workspace.aven_agentic_agents.find(params[:id])
        end

        def agent_params
          params.require(:agent).permit(
            :label, :system_prompt, :user_facing_question, :enabled,
            agent_tools_attributes: [:id, :tool_id, :_destroy],
            agent_documents_attributes: [:id, :document_id, :_destroy]
          )
        end
    end
  end
end
