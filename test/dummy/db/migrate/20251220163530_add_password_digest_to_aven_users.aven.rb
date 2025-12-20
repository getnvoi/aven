# frozen_string_literal: true

# This migration comes from aven (originally 20200101000030)
class AddPasswordDigestToAvenUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :aven_users, :password_digest, :string
  end
end
