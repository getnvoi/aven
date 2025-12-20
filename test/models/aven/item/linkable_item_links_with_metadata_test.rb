# frozen_string_literal: true

require "test_helper"

class Aven::Item::LinkableItemLinksWithMetadataTest < ActiveSupport::TestCase
  def setup
    @workspace = aven_workspaces(:one)
    @contact1 = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "John" })
    @contact2 = Aven::Item.create!(workspace: @workspace, schema_slug: "contact", data: { first_name: "Jane" })
  end

  # What we need: create ItemLinks with metadata via nested attributes
  test "creates ItemLinks with metadata using outgoing_links_attributes" do
    @contact1.outgoing_links_attributes = [
      { target_id: @contact2.id, relation: "spouse", data: { is_primary: true, start_date: "2020-01-01" } }
    ]
    @contact1.save!

    link = Aven::ItemLink.find_by(source_id: @contact1.id, target_id: @contact2.id)
    assert_not_nil link
    assert_equal "spouse", link.relation
    assert_equal true, link.data["is_primary"]
    assert_equal "2020-01-01", link.data["start_date"]
  end

  # Update existing ItemLink metadata
  test "updates ItemLink metadata using outgoing_links_attributes" do
    link = Aven::ItemLink.create!(source: @contact1, target: @contact2, relation: "spouse", data: { is_primary: true })

    @contact1.outgoing_links_attributes = [
      { id: link.id, data: { is_primary: false, end_date: "2023-01-01" } }
    ]
    @contact1.save!

    link.reload
    assert_equal false, link.data["is_primary"]
    assert_equal "2023-01-01", link.data["end_date"]
  end

  # Destroy ItemLink with _destroy flag
  test "destroys ItemLink using outgoing_links_attributes with _destroy" do
    link = Aven::ItemLink.create!(source: @contact1, target: @contact2, relation: "spouse", data: { is_primary: true })

    @contact1.outgoing_links_attributes = [
      { id: link.id, _destroy: "1" }
    ]
    @contact1.save!

    assert_nil Aven::ItemLink.find_by(id: link.id)
  end

  # Deeply nested: update relationship AND target's nested attributes
  test "creates ItemLink and updates target's nested attributes" do
    @contact1.outgoing_links_attributes = [
      {
        target_id: @contact2.id,
        relation: "spouse",
        data: { is_primary: true },
        target_attributes: {
          id: @contact2.id,
          data: {
            emails: [
              { id: SecureRandom.uuid, address: "spouse@example.com", kind: "personal" }
            ]
          }
        }
      }
    ]
    @contact1.save!

    # Verify link was created
    link = Aven::ItemLink.find_by(source_id: @contact1.id, target_id: @contact2.id)
    assert_not_nil link
    assert_equal "spouse", link.relation
    assert_equal true, link.data["is_primary"]

    # Verify target's nested data was updated
    @contact2.reload
    assert_equal 1, @contact2.data["emails"].length
    assert_equal "spouse@example.com", @contact2.data["emails"].first["address"]
  end
end
