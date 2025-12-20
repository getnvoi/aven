# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_item_links
#
#  id         :bigint           not null, primary key
#  position   :integer          default(0)
#  relation   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  source_id  :bigint           not null
#  target_id  :bigint           not null
#
# Indexes
#
#  index_aven_item_links_on_source_id                             (source_id)
#  index_aven_item_links_on_source_id_and_relation                (source_id,relation)
#  index_aven_item_links_on_source_id_and_target_id_and_relation  (source_id,target_id,relation) UNIQUE
#  index_aven_item_links_on_target_id                             (target_id)
#  index_aven_item_links_on_target_id_and_relation                (target_id,relation)
#
# Foreign Keys
#
#  fk_rails_...  (source_id => aven_items.id)
#  fk_rails_...  (target_id => aven_items.id)
#
module Aven
  class ItemLink < ApplicationRecord
    self.table_name = "aven_item_links"

    belongs_to :source, class_name: "Aven::Item"
    belongs_to :target, class_name: "Aven::Item"

    accepts_nested_attributes_for(:target, allow_destroy: true)

    validates :relation, presence: true
    validates :target_id, uniqueness: { scope: [:source_id, :relation] }

    scope :for_relation, ->(rel) { where(relation: rel.to_s) }
    scope :ordered, -> { order(position: :asc) }

    delegate :workspace, :workspace_id, to: :source
  end
end
