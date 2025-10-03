class CreateSqemaUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :sqema_users do |t|
      t.string(:username, null: false)
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

    add_index(:sqema_users, [:email, :auth_tenant], unique: true)
    add_index(:sqema_users, :reset_password_token, unique: true)
    add_index(:sqema_users, :username, unique: true)
  end
end
