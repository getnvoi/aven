# frozen_string_literal: true

module Aven
  module Chat
    class ThreadsController < Aven::ApplicationController
      before_action :authenticate_user!
      before_action :set_thread, only: [:show, :ask, :ask_agent]

      def index
        @threads = current_workspace.aven_chat_threads
          .where(user: current_user)
          .recent
          .limit(50)

        render json: @threads
      end

      def show
        render json: @thread.as_json(
          include: {
            messages: { only: [:id, :role, :status, :content, :created_at] }
          }
        )
      end

      def create
        @thread = current_workspace.aven_chat_threads.build(
          user: current_user,
          **thread_params
        )

        if @thread.save
          render json: @thread, status: :created
        else
          render json: { errors: @thread.errors }, status: :unprocessable_entity
        end
      end

      # POST /chat/threads/:id/ask
      def ask
        message = @thread.ask(params[:question])
        render json: { message: message, thread: @thread }
      end

      # POST /chat/threads/:id/ask_agent
      def ask_agent
        agent = current_workspace.aven_agentic_agents.find(params[:agent_id])
        question = params[:question].presence

        message = @thread.ask_with_agent(agent, question)
        render json: { message: message, thread: @thread }
      end

      private

        def set_thread
          @thread = current_workspace.aven_chat_threads
            .where(user: current_user)
            .find(params[:id])
        end

        def thread_params
          params.permit(:title, :context_markdown)
        end
    end
  end
end
