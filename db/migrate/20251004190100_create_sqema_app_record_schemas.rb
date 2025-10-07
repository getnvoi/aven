class CreateSqemaAppRecordSchemas < ActiveRecord::Migration[8.0]
  def change
    create_table :sqema_app_record_schemas do |t|
      t.jsonb :schema, null: false
      t.references :workspace, null: false, foreign_key: { to_table: :sqema_workspaces }
      t.timestamps
    end

    add_index :sqema_app_record_schemas, :schema, using: :gin
  end
end

