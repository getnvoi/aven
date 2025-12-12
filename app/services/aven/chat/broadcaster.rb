# frozen_string_literal: true

module Aven
  module Chat
    class Broadcaster
      def initialize(thread)
        @thread = thread
      end

      # Broadcast message update
      def broadcast_update(message, **extras)
        broadcast({
          type: "message_updated",
          message: message.as_json.merge(extras)
        })
      end

      # Broadcast tool call started
      def broadcast_tool_call(message)
        broadcast({
          type: "tool_call",
          message: {
            id: message.id,
            tool_name: message.tool_call&.dig("name"),
            status: "calling"
          }
        })
      end

      # Broadcast tool result
      def broadcast_tool_result(message)
        broadcast({
          type: "tool_result",
          message: {
            id: message.id,
            tool_call: message.tool_call
          }
        })
      end

      # Broadcast streaming content
      def broadcast_streaming(message, content)
        broadcast({
          type: "message_streaming",
          message: {
            id: message.id,
            content:
          }
        })
      end

      private

        def broadcast(payload)
          Aven::Chat::ThreadChannel.broadcast_to(@thread, payload)
        end
    end
  end
end
