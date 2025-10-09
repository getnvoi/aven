class CreateAvenUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_users do |t|
      t.string(:email, default: "", null: false)
      t.string(:encrypted_password, default: "", null: false)
      t.string(:reset_password_token)
      t.datetime(:reset_password_sent_at)
      t.datetime(:remember_created_at)
      t.string(:auth_tenant)
      t.string(:remote_id)
      t.string(:access_token)
      t.boolean(:admin, default: false, null: false)
      t.timestamps
    end

    add_index(:aven_users, [:email, :auth_tenant], unique: true)
    add_index(:aven_users, :reset_password_token, unique: true)
  end
end
