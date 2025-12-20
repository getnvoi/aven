# frozen_string_literal: true

# This migration comes from aven (originally 20200101000019)
class CreateAvenChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_chat_messages do |t|
      t.references :thread, null: false, foreign_key: { to_table: :aven_chat_threads }
      t.references :parent, foreign_key: { to_table: :aven_chat_messages }
      t.string :role, null: false                 # user, assistant, tool, system
      t.string :status, default: "pending"        # pending, streaming, success, error
      t.text :content
      t.string :model
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0
      t.integer :total_tokens, default: 0
      t.decimal :cost_usd, precision: 10, scale: 6, default: 0.0
      t.datetime :started_at
      t.datetime :completed_at
      t.jsonb :tool_call, default: nil            # Tool call details
      t.timestamps
    end

    add_index :aven_chat_messages, :role
    add_index :aven_chat_messages, :status
    add_index :aven_chat_messages, [:thread_id, :created_at]
  end
end
