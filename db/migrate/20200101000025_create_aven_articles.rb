# frozen_string_literal: true

class CreateAvenArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_articles do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.references :author, null: true, foreign_key: { to_table: :aven_users }
      t.string :title, null: false
      t.string :slug
      t.text :intro
      t.text :description
      t.datetime :published_at
      t.timestamps
    end

    add_index :aven_articles, [:workspace_id, :slug], unique: true
    add_index :aven_articles, :published_at
  end
end
