# frozen_string_literal: true

# This migration comes from aven (originally 20200101000026)
class CreateAvenArticleAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_article_attachments do |t|
      t.references :article, null: false, foreign_key: { to_table: :aven_articles }
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :aven_article_attachments, [:article_id, :position]
  end
end
