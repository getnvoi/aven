# frozen_string_literal: true

module Aven
  module Ai
    class TextController < Aven::ApplicationController
      include Aven::Authentication
      include ActionController::Live

      before_action :authenticate_user!

      def generate
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"

        model = params[:model] || "gpt-4o-mini"
        chat = RubyLLM.chat(model:)

        # Apply system prompts if provided
        if params[:system_prompts].present?
          Array(params[:system_prompts]).each do |system_prompt|
            chat.with_instructions(system_prompt)
          end
        end

        # Stream the response
        chat.ask(params[:prompt]) do |chunk|
          content = chunk.respond_to?(:content) ? chunk.content : chunk.to_s
          response.stream.write "data: #{content.to_json}\n\n"
        end

        response.stream.write "data: [DONE]\n\n"
      rescue => e
        Rails.logger.error "AI generation error: #{e.message}"
        response.stream.write "data: #{JSON.generate(error: e.message)}\n\n"
      ensure
        response.stream.close
      end
    end
  end
end
