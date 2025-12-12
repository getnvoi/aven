# frozen_string_literal: true

class CreateAvenAgenticDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_agentic_documents do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.string :filename, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.string :ocr_status, default: "pending", null: false
      t.text :ocr_content
      t.string :embedding_status, default: "pending", null: false
      t.jsonb :metadata, default: {}
      t.datetime :processed_at
      t.timestamps
    end

    add_index :aven_agentic_documents, :ocr_status
    add_index :aven_agentic_documents, :embedding_status
    add_index :aven_agentic_documents, :content_type
  end
end
