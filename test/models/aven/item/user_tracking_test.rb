# frozen_string_literal: true

require "test_helper"

module Aven
  class Item::UserTrackingTest < ActiveSupport::TestCase
    def self.startup
      # Reset column information and clear attribute methods cache
      Aven::Item.reset_column_information
      Aven::Item.undefine_attribute_methods if Aven::Item.attribute_methods_generated?
      Aven::Item.define_attribute_methods
    end

    setup do
      @workspace = aven_workspaces(:one)
      @user1 = aven_users(:one)
      @user2 = aven_users(:two)
    end

    test "item can be created with created_by" do
      item = nil
      Aven::Item.skip_callback(:validate, :before, :validate_data_against_schema)

      item = Aven::Item.create!(
        workspace: @workspace,
        schema_slug: "test",
        data: { name: "Test" },
        created_by: @user1
      )

      assert_equal @user1, item.created_by
      assert_equal @user1.id, item.created_by_id
    ensure
      Aven::Item.set_callback(:validate, :before, :validate_data_against_schema)
    end

    test "item can be created without created_by (optional)" do
      Aven::Item.skip_callback(:validate, :before, :validate_data_against_schema)

      item = Aven::Item.create!(
        workspace: @workspace,
        schema_slug: "test",
        data: { name: "Test" }
      )

      assert_nil item.created_by
      assert_nil item.created_by_id
    ensure
      Aven::Item.set_callback(:validate, :before, :validate_data_against_schema)
    end

    test "item tracks updated_by when updated" do
      Aven::Item.skip_callback(:validate, :before, :validate_data_against_schema)

      item = Aven::Item.create!(
        workspace: @workspace,
        schema_slug: "test",
        data: { name: "Test" },
        created_by: @user1
      )

      item.update!(data: { name: "Updated" }, updated_by: @user2)

      assert_equal @user1, item.created_by
      assert_equal @user2, item.updated_by
    ensure
      Aven::Item.set_callback(:validate, :before, :validate_data_against_schema)
    end

    test "created_by association loads user" do
      Aven::Item.skip_callback(:validate, :before, :validate_data_against_schema)

      item = Aven::Item.create!(
        workspace: @workspace,
        schema_slug: "test",
        data: { name: "Test" },
        created_by: @user1
      )

      loaded_item = Aven::Item.find(item.id)
      assert_equal @user1.email, loaded_item.created_by.email
    ensure
      Aven::Item.set_callback(:validate, :before, :validate_data_against_schema)
    end

    test "updated_by association loads user" do
      Aven::Item.skip_callback(:validate, :before, :validate_data_against_schema)

      item = Aven::Item.create!(
        workspace: @workspace,
        schema_slug: "test",
        data: { name: "Test" },
        created_by: @user1,
        updated_by: @user2
      )

      loaded_item = Aven::Item.find(item.id)
      assert_equal @user2.email, loaded_item.updated_by.email
    ensure
      Aven::Item.set_callback(:validate, :before, :validate_data_against_schema)
    end
  end
end
