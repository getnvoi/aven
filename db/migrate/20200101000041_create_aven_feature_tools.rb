# frozen_string_literal: true

class CreateAvenFeatureTools < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_feature_tools do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :tool_type
      t.jsonb :config, default: {}
      t.datetime :deleted_at
      t.references :feature, null: false, foreign_key: { to_table: :aven_features }
      t.bigint :schema_id, null: true

      t.timestamps
    end

    add_index :aven_feature_tools, [:slug, :feature_id], unique: true
    add_index :aven_feature_tools, :deleted_at
    add_index :aven_feature_tools, :schema_id
  end
end
