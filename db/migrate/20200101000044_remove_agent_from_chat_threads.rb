# frozen_string_literal: true

class RemoveAgentFromChatThreads < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :aven_chat_threads, column: :agent_id if foreign_key_exists?(:aven_chat_threads, column: :agent_id)
    remove_column :aven_chat_threads, :agent_id, :bigint if column_exists?(:aven_chat_threads, :agent_id)
    remove_index :aven_chat_threads, :agent_id if index_exists?(:aven_chat_threads, :agent_id)
  end
end
