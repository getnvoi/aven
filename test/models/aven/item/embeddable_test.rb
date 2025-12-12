# frozen_string_literal: true

require "test_helper"

class Aven::Item::EmbeddableTest < ActiveSupport::TestCase
  def setup
    @workspace = aven_workspaces(:one)
    @item = Aven::Item.new(workspace: @workspace, schema_slug: "contact", data: {})
  end

  # Callbacks
  test "before_validation :assign_embed_ids is registered" do
    callbacks = Aven::Item._validation_callbacks.map(&:filter)
    assert_includes callbacks, :assign_embed_ids
  end

  # assign_embed_ids
  test "assigns uuid to embeds without id" do
    @item.data["addresses"] = [{ "city" => "SF" }, { "city" => "LA" }]
    @item.valid?
    assert_match(/\A[0-9a-f-]{36}\z/, @item.data["addresses"][0]["id"])
    assert_match(/\A[0-9a-f-]{36}\z/, @item.data["addresses"][1]["id"])
  end

  test "preserves existing ids" do
    @item.data["addresses"] = [{ "id" => "existing-id", "city" => "SF" }]
    @item.valid?
    assert_equal "existing-id", @item.data["addresses"][0]["id"]
  end

  test "handles empty array" do
    @item.data["addresses"] = []
    assert_nothing_raised { @item.valid? }
  end

  test "handles nil data" do
    @item.data["addresses"] = nil
    assert_nothing_raised { @item.valid? }
  end

  # process_embed_attributes with embeds_many
  test "adding new embeds creates embed with new uuid" do
    @item.send(:process_embed_attributes, :addresses, [{ city: "SF" }])
    assert_equal 1, @item.data["addresses"].length
    assert @item.data["addresses"][0]["id"].present?
    assert_equal "SF", @item.data["addresses"][0]["city"]
  end

  test "ignores _destroy flag for new embeds without id" do
    @item.send(:process_embed_attributes, :addresses, [{ city: "SF", _destroy: "1" }])
    assert_equal [], @item.data["addresses"]
  end

  test "handles array format" do
    @item.send(:process_embed_attributes, :addresses, [{ city: "SF" }, { city: "LA" }])
    assert_equal 2, @item.data["addresses"].length
  end

  test "handles hash format with indices" do
    @item.send(:process_embed_attributes, :addresses, { "0" => { city: "SF" }, "1" => { city: "LA" } })
    assert_equal 2, @item.data["addresses"].length
  end

  # Updating existing embeds
  test "finds embed by id and updates" do
    @item.data["addresses"] = [{ "id" => "addr-1", "city" => "SF", "street" => "Main" }]
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", city: "LA" }])
    assert_equal 1, @item.data["addresses"].length
    assert_equal "addr-1", @item.data["addresses"][0]["id"]
    assert_equal "LA", @item.data["addresses"][0]["city"]
  end

  test "merges new attributes preserving unmodified" do
    @item.data["addresses"] = [{ "id" => "addr-1", "city" => "SF", "street" => "Main" }]
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", city: "LA" }])
    assert_equal "Main", @item.data["addresses"][0]["street"]
  end

  # Destroying embeds
  test "removes embed when _destroy is '1'" do
    @item.data["addresses"] = [
      { "id" => "addr-1", "city" => "SF" },
      { "id" => "addr-2", "city" => "LA" }
    ]
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", _destroy: "1" }])
    assert_equal 1, @item.data["addresses"].length
    assert_equal "addr-2", @item.data["addresses"][0]["id"]
  end

  test "removes embed when _destroy is true" do
    @item.data["addresses"] = [
      { "id" => "addr-1", "city" => "SF" },
      { "id" => "addr-2", "city" => "LA" }
    ]
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", _destroy: true }])
    assert_equal 1, @item.data["addresses"].length
  end

  test "keeps embed when _destroy is '0'" do
    @item.data["addresses"] = [
      { "id" => "addr-1", "city" => "SF" },
      { "id" => "addr-2", "city" => "LA" }
    ]
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", _destroy: "0", city: "NYC" }])
    assert_equal 2, @item.data["addresses"].length
    assert_equal "NYC", @item.data["addresses"][0]["city"]
  end

  test "keeps embed when _destroy is absent" do
    @item.data["addresses"] = [
      { "id" => "addr-1", "city" => "SF" },
      { "id" => "addr-2", "city" => "LA" }
    ]
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", city: "NYC" }])
    assert_equal 2, @item.data["addresses"].length
  end

  # Mixed operations
  test "handles add, update, destroy in single call" do
    @item.data["addresses"] = [
      { "id" => "addr-1", "city" => "SF" },
      { "id" => "addr-2", "city" => "LA" }
    ]
    @item.send(:process_embed_attributes, :addresses, [
      { id: "addr-1", _destroy: "1" },
      { id: "addr-2", city: "Los Angeles" },
      { city: "NYC" }
    ])
    assert_equal 2, @item.data["addresses"].length
    cities = @item.data["addresses"].map { |a| a["city"] }
    assert_includes cities, "Los Angeles"
    assert_includes cities, "NYC"
    assert_not_includes cities, "SF"
  end

  # normalize_attrs
  test "normalize_attrs handles array input" do
    result = @item.send(:normalize_attrs, [{ city: "SF" }])
    assert_instance_of Array, result
    assert_equal 1, result.length
  end

  test "normalize_attrs handles hash with numeric keys" do
    result = @item.send(:normalize_attrs, { "0" => { city: "SF" }, "1" => { city: "LA" } })
    assert_equal 2, result.length
  end

  test "normalize_attrs handles hash with string keys" do
    result = @item.send(:normalize_attrs, { city: "SF" })
    assert_equal 1, result.length
  end

  test "normalize_attrs returns array of indifferent access hashes" do
    result = @item.send(:normalize_attrs, [{ city: "SF" }])
    assert_equal "SF", result[0][:city]
    assert_equal "SF", result[0]["city"]
  end

  # clean_attrs
  test "clean_attrs removes _destroy key" do
    result = @item.send(:clean_attrs, { city: "SF", _destroy: "1" })
    assert_not result.key?(:_destroy)
    assert_not result.key?("_destroy")
  end

  test "clean_attrs stringifies all keys" do
    result = @item.send(:clean_attrs, { city: "SF" })
    assert_equal ["city"], result.keys
  end

  test "clean_attrs preserves other attributes" do
    result = @item.send(:clean_attrs, { city: "SF", street: "Main", _destroy: "0" })
    assert_equal "SF", result["city"]
    assert_equal "Main", result["street"]
  end

  # destroy_flag?
  test "destroy_flag? returns true for symbol _destroy '1'" do
    assert @item.send(:destroy_flag?, { _destroy: "1" })
  end

  test "destroy_flag? returns true for symbol _destroy true" do
    assert @item.send(:destroy_flag?, { _destroy: true })
  end

  test "destroy_flag? returns true for string _destroy '1'" do
    assert @item.send(:destroy_flag?, { "_destroy" => "1" })
  end

  test "destroy_flag? returns false for '0'" do
    assert_not @item.send(:destroy_flag?, { _destroy: "0" })
  end

  test "destroy_flag? returns false for false" do
    assert_not @item.send(:destroy_flag?, { _destroy: false })
  end

  test "destroy_flag? returns false for nil" do
    assert_not @item.send(:destroy_flag?, { _destroy: nil })
  end

  test "destroy_flag? returns false for absent key" do
    assert_not @item.send(:destroy_flag?, { city: "SF" })
  end

  # Cache invalidation
  test "clears embed cache on process_embed_attributes" do
    @item.data["addresses"] = [{ "id" => "addr-1", "city" => "SF" }]
    first_addresses = @item.addresses
    @item.send(:process_embed_attributes, :addresses, [{ id: "addr-1", city: "LA" }])
    assert_equal "LA", @item.addresses.first.city
    assert_not_equal first_addresses.object_id, @item.addresses.object_id
  end

  test "clears embed cache on setter" do
    @item.data["addresses"] = [{ "city" => "SF" }]
    first_addresses = @item.addresses
    @item.addresses = [{ city: "LA" }]
    assert_equal "LA", @item.addresses.first.city
    assert_not_equal first_addresses.object_id, @item.addresses.object_id
  end
end
