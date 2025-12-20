# frozen_string_literal: true

# This migration comes from aven (originally 20200101000040)
class AddRegxFieldsToAvenFeatures < ActiveRecord::Migration[7.2]
  def change
    add_column :aven_features, :auto_activate, :boolean, default: false, null: false
    add_column :aven_features, :deleted_at, :datetime
    add_column :aven_features, :editorial_title, :string
    add_column :aven_features, :editorial_description, :text
    add_column :aven_features, :editorial_body, :text
    add_column :aven_features, :config, :jsonb, default: {}

    add_index :aven_features, :deleted_at
  end
end
