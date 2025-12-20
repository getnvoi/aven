# frozen_string_literal: true

class AddPasswordDigestToAvenUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :aven_users, :password_digest, :string
  end
end
