class CreateAvenLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_logs do |t|
      t.string :level, null: false, default: "info"
      t.string :loggable_type, null: false
      t.bigint :loggable_id, null: false
      t.text :message, null: false
      t.jsonb :metadata
      t.string :state
      t.string :state_machine
      t.string :run_id
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.timestamps
    end

    add_index :aven_logs, :created_at
    add_index :aven_logs, :level
    add_index :aven_logs, [ :loggable_type, :loggable_id ], name: "index_aven_logs_on_loggable"
    add_index :aven_logs, [ :loggable_type, :loggable_id, :run_id, :state, :created_at ], name: "idx_aven_logs_on_loggable_run_state_created_at"
  end
end
