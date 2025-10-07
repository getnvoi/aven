class CreateSqemaAppRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sqema_app_records do |t|
      t.jsonb :data, null: false
      t.references :app_record_schema, null: false, foreign_key: { to_table: :sqema_app_record_schemas }
      t.timestamps
    end

    add_index :sqema_app_records, :data, using: :gin
  end
end

