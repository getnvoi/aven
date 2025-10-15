class CreateAvenAppRecordSchemas < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_app_record_schemas do |t|
      t.jsonb :schema, null: false
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.timestamps
    end

    add_index :aven_app_record_schemas, :schema, using: :gin
  end
end
