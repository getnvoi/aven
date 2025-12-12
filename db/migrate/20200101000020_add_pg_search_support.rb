# frozen_string_literal: true

class AddPgSearchSupport < ActiveRecord::Migration[8.0]
  def up
    # Enable pg_trgm for fuzzy matching
    enable_extension "pg_trgm"

    # Create pg_search_documents table for multi-search
    create_table :pg_search_documents do |t|
      t.text :content
      t.belongs_to :searchable, polymorphic: true, index: true
      t.belongs_to :workspace, foreign_key: { to_table: :aven_workspaces }, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :pg_search_documents
    disable_extension "pg_trgm"
  end
end
