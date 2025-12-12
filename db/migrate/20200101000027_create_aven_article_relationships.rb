# frozen_string_literal: true

class CreateAvenArticleRelationships < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_article_relationships do |t|
      t.references :article, null: false, foreign_key: { to_table: :aven_articles }
      t.references :related_article, null: false, foreign_key: { to_table: :aven_articles }
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :aven_article_relationships, [:article_id, :related_article_id], unique: true, name: "idx_article_relationships_unique"
    add_index :aven_article_relationships, [:article_id, :position]
  end
end
