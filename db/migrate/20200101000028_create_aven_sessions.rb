# frozen_string_literal: true

class CreateAvenSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_sessions do |t|
      t.references(:user, null: false, foreign_key: { to_table: :aven_users })
      t.string(:ip_address)
      t.string(:user_agent)
      t.datetime(:last_active_at)
      t.timestamps
    end

    add_index(:aven_sessions, :updated_at)
  end
end
