# frozen_string_literal: true

class CreateAvenAgenticToolParameters < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_agentic_tool_parameters do |t|
      t.references :tool, null: false, foreign_key: { to_table: :aven_agentic_tools }
      t.string :name, null: false
      t.string :param_type, null: false
      t.text :description
      t.text :default_description
      t.boolean :required, default: false, null: false
      t.jsonb :constraints, default: {}
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :aven_agentic_tool_parameters, [:tool_id, :name], unique: true
    add_index :aven_agentic_tool_parameters, [:tool_id, :position]
  end
end
