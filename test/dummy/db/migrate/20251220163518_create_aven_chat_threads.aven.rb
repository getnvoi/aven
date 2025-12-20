# frozen_string_literal: true

# This migration comes from aven (originally 20200101000018)
class CreateAvenChatThreads < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_chat_threads do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.references :user, null: false, foreign_key: { to_table: :aven_users }
      t.string :title
      t.jsonb :tools, default: nil           # Locked tool names array
      t.jsonb :documents, default: nil       # Locked document IDs array
      t.text :context_markdown
      t.timestamps
    end

    add_index :aven_chat_threads, [:workspace_id, :user_id]
    add_index :aven_chat_threads, :created_at
  end
end
