class CreateAvenAppRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_app_records do |t|
      t.jsonb :data, null: false
      t.references :app_record_schema, null: false, foreign_key: { to_table: :aven_app_record_schemas }
      t.timestamps
    end

    add_index :aven_app_records, :data, using: :gin
  end
end

