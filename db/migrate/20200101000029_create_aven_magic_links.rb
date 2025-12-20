# frozen_string_literal: true

class CreateAvenMagicLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_magic_links do |t|
      t.references(:user, null: false, foreign_key: { to_table: :aven_users })
      t.string(:code, null: false)
      t.integer(:purpose, null: false, default: 0)
      t.datetime(:expires_at, null: false)
      t.timestamps
    end

    add_index(:aven_magic_links, :code, unique: true)
    add_index(:aven_magic_links, :expires_at)
  end
end
