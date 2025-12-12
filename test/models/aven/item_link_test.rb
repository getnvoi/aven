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
require "test_helper"

class Aven::ItemLinkTest < ActiveSupport::TestCase
  # Associations
  test "belongs to source" do
    link = aven_item_links(:contact_company_link)
    assert_respond_to link, :source
    assert_equal aven_items(:contact_one), link.source
  end

  test "belongs to target" do
    link = aven_item_links(:contact_company_link)
    assert_respond_to link, :target
    assert_equal aven_items(:company_one), link.target
  end

  # Validations
  test "requires relation" do
    link = Aven::ItemLink.new(source: aven_items(:contact_one), target: aven_items(:company_one))
    assert_not link.valid?
    assert_includes link.errors[:relation], "can't be blank"
  end

  test "validates uniqueness of target within source and relation" do
    existing = aven_item_links(:contact_company_link)
    link = Aven::ItemLink.new(
      source: existing.source,
      target: existing.target,
      relation: existing.relation
    )
    assert_not link.valid?
    assert_includes link.errors[:target_id], "has already been taken"
  end

  test "allows same target with different relation" do
    link = Aven::ItemLink.new(
      source: aven_items(:contact_one),
      target: aven_items(:company_one),
      relation: "different_relation"
    )
    assert link.valid?
  end

  # Scopes
  test "for_relation scope filters by relation" do
    links = Aven::ItemLink.for_relation("company")
    assert_includes links, aven_item_links(:contact_company_link)
    assert_not_includes links, aven_item_links(:contact_note_link_one)
  end

  test "ordered scope orders by position" do
    link1 = Aven::ItemLink.create!(source: aven_items(:contact_two), target: aven_items(:note_one), relation: "notes", position: 1)
    link2 = Aven::ItemLink.create!(source: aven_items(:contact_two), target: aven_items(:company_one), relation: "notes", position: 0)

    links = Aven::ItemLink.where(source: aven_items(:contact_two)).ordered
    assert_equal link2, links.first
    assert_equal link1, links.last
  end

  # Delegation
  test "delegates workspace to source" do
    link = aven_item_links(:contact_company_link)
    assert_equal link.source.workspace, link.workspace
  end

  test "delegates workspace_id to source" do
    link = aven_item_links(:contact_company_link)
    assert_equal link.source.workspace_id, link.workspace_id
  end

  # Position
  test "default position is 0" do
    link = Aven::ItemLink.create!(source: aven_items(:contact_two), target: aven_items(:company_one), relation: "test")
    assert_equal 0, link.position
  end
end
