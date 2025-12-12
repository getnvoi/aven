# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_import_entries
#
#  id         :bigint           not null, primary key
#  data       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  import_id  :bigint           not null
#
# Indexes
#
#  index_aven_import_entries_on_data       (data) USING gin
#  index_aven_import_entries_on_import_id  (import_id)
#
# Foreign Keys
#
#  fk_rails_...  (import_id => aven_imports.id)
#
module Aven
  class Import::Entry < ApplicationRecord
    self.table_name = "aven_import_entries"

    belongs_to :import, class_name: "Aven::Import"
    has_many :item_links, class_name: "Aven::Import::ItemLink", foreign_key: :entry_id, dependent: :destroy
    has_many :items, through: :item_links, class_name: "Aven::Item"

    validates :data, presence: true

    scope :linked, -> { joins(:item_links).distinct }
    scope :unlinked, -> { where.missing(:item_links) }

    delegate :workspace, to: :import

    def linked?
      item_links.exists?
    end

    def link_to_item!(item)
      item_links.create!(item:)
    end
  end
end
