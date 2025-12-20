# This migration comes from aven (originally 20200101000031)
class CreateAvenItemRecipients < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_item_recipients do |t|
      # ACL references (both optional - flexible pattern)
      t.references :source_item, foreign_key: { to_table: :aven_items }
      t.references :target_item, foreign_key: { to_table: :aven_items }
      t.references :user, foreign_key: { to_table: :aven_users }

      # Workspace & creator
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.references :created_by, null: false, foreign_key: { to_table: :aven_users }

      t.integer :position, default: 0

      # Security
      t.string :security_level, default: 'none'
      t.datetime :otp_sent_at

      # Workflow
      t.string :completion_state, default: 'pending'
      t.datetime :completed_at

      # Delegation
      t.references :delegated_from_recipient, foreign_key: { to_table: :aven_item_recipients }
      t.boolean :allow_delegate, default: false

      # Linking
      t.references :invitee, foreign_key: { to_table: :aven_users }

      t.timestamps
    end

    add_index :aven_item_recipients, [:source_item_id, :target_item_id], name: 'index_item_recipients_source_target'
    add_index :aven_item_recipients, :completion_state
  end
end
