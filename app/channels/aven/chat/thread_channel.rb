# frozen_string_literal: true

module Aven
  module Chat
    class ThreadChannel < ActionCable::Channel::Base
      def subscribed
        thread = find_thread
        return reject unless thread

        stream_for thread
      end

      def unsubscribed
        stop_all_streams
      end

      private

        def find_thread
          thread_id = params[:thread_id]
          return nil unless thread_id

          # Verify user has access to this thread
          if current_user
            Aven::Chat::Thread
              .joins(:workspace)
              .joins("INNER JOIN aven_workspace_users ON aven_workspace_users.workspace_id = aven_chat_threads.workspace_id")
              .where(aven_workspace_users: { user_id: current_user.id })
              .find_by(id: thread_id)
          end
        end

        def current_user
          # Access current_user from connection
          connection.current_user if connection.respond_to?(:current_user)
        end
    end
  end
end
