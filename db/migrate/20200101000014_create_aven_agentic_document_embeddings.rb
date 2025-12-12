# frozen_string_literal: true

class CreateAvenAgenticDocumentEmbeddings < ActiveRecord::Migration[8.0]
  def change
    # Enable pgvector extension for vector similarity search
    enable_extension "vector"

    create_table :aven_agentic_document_embeddings do |t|
      t.references :document, null: false, foreign_key: { to_table: :aven_agentic_documents }
      t.integer :chunk_index, null: false
      t.text :content, null: false
      t.vector :embedding, limit: 1536  # OpenAI ada-002 dimensions
      t.timestamps
    end

    add_index :aven_agentic_document_embeddings, [:document_id, :chunk_index], unique: true
  end
end
