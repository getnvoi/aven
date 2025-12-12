# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_import_item_links
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  entry_id   :bigint           not null
#  item_id    :bigint           not null
#
# Indexes
#
#  index_aven_import_item_links_on_entry_id              (entry_id)
#  index_aven_import_item_links_on_entry_id_and_item_id  (entry_id,item_id) UNIQUE
#  index_aven_import_item_links_on_item_id               (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (entry_id => aven_import_entries.id)
#  fk_rails_...  (item_id => aven_items.id)
#
module Aven
  class Import::ItemLink < ApplicationRecord
    self.table_name = "aven_import_item_links"

    belongs_to :entry, class_name: "Aven::Import::Entry"
    belongs_to :item, class_name: "Aven::Item"

    validates :entry_id, uniqueness: { scope: :item_id }

    delegate :import, :workspace, to: :entry
    delegate :schema_slug, to: :item
  end
end
