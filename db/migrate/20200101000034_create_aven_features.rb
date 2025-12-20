# frozen_string_literal: true

class CreateAvenFeatures < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_features do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.string :feature_type, null: false, default: 'boolean' # boolean, usage_based, tiered
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :aven_features, :slug, unique: true
    add_index :aven_features, :feature_type
  end
end
