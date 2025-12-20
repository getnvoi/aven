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
require "test_helper"

module Aven
  class ItemDocumentTest < ActiveSupport::TestCase
    def setup
      @workspace = aven_workspaces(:one)
      @item = aven_items(:company_one)
      @user = aven_users(:one)
      @file = create_test_file
    end

    private

      def create_test_file
        {
          io: StringIO.new("This is a test file"),
          filename: 'test.txt',
          content_type: 'text/plain'
        }
      end

    test "valid item document" do
      doc = ItemDocument.new(
        item: @item,
        workspace: @workspace,
        uploaded_by: @user
      )
      doc.file.attach(@file)
      assert doc.valid?
    end

    test "requires item" do
      doc = ItemDocument.new(
        workspace: @workspace
      )
      doc.file.attach(@file)
      assert_not doc.valid?
      assert_includes doc.errors[:item], "must exist"
    end

    test "requires workspace" do
      doc = ItemDocument.new(
        item: @item
      )
      doc.file.attach(@file)
      assert_not doc.valid?
      assert_includes doc.errors[:workspace], "must exist"
    end

    test "file attachment is optional" do
      doc = ItemDocument.new(
        item: @item,
        workspace: @workspace
      )
      assert doc.valid?
    end

    test "uploaded_by is optional" do
      doc = ItemDocument.new(
        item: @item,
        workspace: @workspace,
        uploaded_by: nil
      )
      doc.file.attach(@file)
      assert doc.valid?
    end

    test "belongs to item" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace
      )
      doc.file.attach(@file)
      assert_equal @item, doc.item
    end

    test "belongs to workspace" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace
      )
      doc.file.attach(@file)
      assert_equal @workspace, doc.workspace
    end

    test "belongs to uploaded_by when set" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace,
        uploaded_by: @user
      )
      doc.file.attach(@file)
      assert_equal @user, doc.uploaded_by
    end

    test "has file attachment" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace
      )
      doc.file.attach(@file)
      assert doc.file.attached?
      assert_equal 'test.txt', doc.file.filename.to_s
    end

    test "stores label" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace,
        label: 'Test Document'
      )
      doc.file.attach(@file)
      assert_equal 'Test Document', doc.label
    end

    test "stores description" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace,
        description: 'This is a test document'
      )
      doc.file.attach(@file)
      assert_equal 'This is a test document', doc.description
    end

    test "stores metadata as jsonb" do
      metadata = { category: 'invoice', year: 2024 }
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace,
        metadata: metadata
      )
      doc.file.attach(@file)
      assert_equal metadata.stringify_keys, doc.metadata
    end

    test "metadata defaults to empty hash" do
      doc = ItemDocument.create!(
        item: @item,
        workspace: @workspace
      )
      doc.file.attach(@file)
      assert_equal({}, doc.metadata)
    end
  end
end
