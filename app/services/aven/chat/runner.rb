# frozen_string_literal: true

module Aven
  module Chat
    class Runner
      def initialize(thread, assistant_message)
        @thread = thread
        @assistant_message = assistant_message
        @broadcaster = Broadcaster.new(thread)
        @full_content = ""
        @current_tool_call = nil
      end

      # Run LLM chat with streaming
      # @param messages [Array<Hash>] Message history
      # @return [OpenStruct] Response with content, model_id, tokens
      def run(messages)
        chat = build_chat

        # Add conversation history (all messages except the last)
        messages[0..-2].each do |msg|
          chat.add_message(role: msg[:role].to_sym, content: msg[:content])
        end

        # Ask with the last message
        response = chat.ask(messages.last[:content]) do |chunk|
          handle_stream_chunk(chunk)
        end

        build_response(response)
      end

      private

        def build_chat
          chat = RubyLLM.chat(model: Config.model)
            .with_instructions(Config.system_prompt(thread: @thread))
            .with_tools(*Config.tools(@thread))

          chat.on_tool_call do |tool_call|
            handle_tool_call(tool_call)
          end

          chat.on_tool_result do |result|
            handle_tool_result(result)
          end

          chat
        end

        def handle_stream_chunk(chunk)
          return unless chunk.content

          @full_content += chunk.content
          @assistant_message.append_content!(chunk.content)
        end

        def handle_tool_call(tool_call)
          @current_tool_call = tool_call

          tool_message = @thread.messages.create!(
            role: :tool,
            parent: @assistant_message.parent,
            status: :streaming,
            content: tool_call.name,
            tool_call: {
              id: tool_call.id,
              name: tool_call.name,
              arguments: tool_call.arguments,
              status: "calling"
            }
          )

          @broadcaster.broadcast_tool_call(tool_message)
          tool_message
        end

        def handle_tool_result(result)
          return unless @current_tool_call

          tool_message = @thread.messages.by_tool_call_id(@current_tool_call.id).first
          return unless tool_message

          tool_message.update!(
            status: :success,
            tool_call: tool_message.tool_call.merge(
              "result" => result,
              "status" => "completed"
            )
          )

          @broadcaster.broadcast_tool_result(tool_message)
        end

        def build_response(response)
          OpenStruct.new(
            content: @full_content,
            model_id: response.model_id,
            input_tokens: response.input_tokens || 0,
            output_tokens: response.output_tokens || 0
          )
        end
    end
  end
end
