# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_item_documents
#
#  id             :bigint           not null, primary key
#  description    :text
#  label          :string
#  metadata       :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  item_id        :bigint           not null
#  uploaded_by_id :bigint
#  workspace_id   :bigint           not null
#
# Indexes
#
#  index_aven_item_documents_on_item_id         (item_id)
#  index_aven_item_documents_on_metadata        (metadata) USING gin
#  index_aven_item_documents_on_uploaded_by_id  (uploaded_by_id)
#  index_aven_item_documents_on_workspace_id    (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => aven_items.id)
#  fk_rails_...  (uploaded_by_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class ItemDocument < ApplicationRecord
    self.table_name = 'aven_item_documents'

    # Associations
    belongs_to :item, class_name: 'Aven::Item'
    belongs_to :workspace, class_name: 'Aven::Workspace'
    belongs_to :uploaded_by, class_name: 'Aven::User', optional: true

    # File attachment
    has_one_attached :file
  end
end
