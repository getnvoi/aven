# This migration comes from aven (originally 20200101000032)
class CreateAvenInvites < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_invites do |t|
      # Links
      t.references :item_recipient, foreign_key: { to_table: :aven_item_recipients }
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }

      # Type
      t.string :invite_type, null: false

      # Contact (immutable snapshot)
      t.string :invitee_email, null: false
      t.string :invitee_phone

      # Auth
      t.string :auth_link_hash, null: false

      # Lifecycle
      t.datetime :sent_at
      t.datetime :expires_at

      # Delivery
      t.string :status, default: 'pending'

      t.timestamps
    end

    add_index :aven_invites, :auth_link_hash, unique: true
    add_index :aven_invites, :invitee_email
    add_index :aven_invites, :invite_type
  end
end
