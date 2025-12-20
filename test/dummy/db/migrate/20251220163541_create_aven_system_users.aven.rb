# frozen_string_literal: true

# This migration comes from aven (originally 20200101000046)
class CreateAvenSystemUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_system_users do |t|
      t.string :email, null: false, default: ""
      t.string :password_digest, null: false
      t.string :name
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
    end

    add_index :aven_system_users, :email, unique: true
    add_index :aven_system_users, :reset_password_token, unique: true
  end
end
