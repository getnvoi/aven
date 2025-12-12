# frozen_string_literal: true

require "test_helper"

class Aven::Item::EmbedTest < ActiveSupport::TestCase
  test "initializes with attributes" do
    embed = Aven::Item::Embed.new(city: "San Francisco", street: "123 Main St")
    assert_equal "San Francisco", embed.city
    assert_equal "123 Main St", embed.street
  end

  test "initializes with nil attributes" do
    embed = Aven::Item::Embed.new(nil)
    assert_equal({}, embed.to_h)
  end

  test "reads id from attributes" do
    embed = Aven::Item::Embed.new("id" => "abc-123", "city" => "SF")
    assert_equal "abc-123", embed.id
  end

  test "bracket accessor reads attributes" do
    embed = Aven::Item::Embed.new(city: "SF")
    assert_equal "SF", embed["city"]
    assert_equal "SF", embed[:city]
  end

  test "bracket accessor writes attributes" do
    embed = Aven::Item::Embed.new({})
    embed["city"] = "SF"
    assert_equal "SF", embed.city
  end

  test "to_h returns attributes hash" do
    embed = Aven::Item::Embed.new(city: "SF", street: "Main")
    hash = embed.to_h
    assert_equal "SF", hash["city"]
    assert_equal "Main", hash["street"]
  end

  test "to_hash is alias for to_h" do
    embed = Aven::Item::Embed.new(city: "SF")
    assert_equal embed.to_h, embed.to_hash
  end

  test "persisted? returns true when id is present" do
    embed = Aven::Item::Embed.new("id" => "abc-123")
    assert embed.persisted?
  end

  test "persisted? returns false when id is blank" do
    embed = Aven::Item::Embed.new({})
    assert_not embed.persisted?
  end

  test "new_record? returns opposite of persisted?" do
    embed_with_id = Aven::Item::Embed.new("id" => "abc")
    embed_without_id = Aven::Item::Embed.new({})

    assert_not embed_with_id.new_record?
    assert embed_without_id.new_record?
  end

  test "marked_for_destruction? returns true when _destroy is '1'" do
    embed = Aven::Item::Embed.new({})
    embed._destroy = "1"
    assert embed.marked_for_destruction?
  end

  test "marked_for_destruction? returns true when _destroy is true" do
    embed = Aven::Item::Embed.new({})
    embed._destroy = true
    assert embed.marked_for_destruction?
  end

  test "marked_for_destruction? returns false when _destroy is absent" do
    embed = Aven::Item::Embed.new({})
    assert_not embed.marked_for_destruction?
  end

  test "method_missing handles dynamic getters" do
    embed = Aven::Item::Embed.new(foo: "bar")
    assert_equal "bar", embed.foo
  end

  test "method_missing handles dynamic setters" do
    embed = Aven::Item::Embed.new({})
    embed.foo = "bar"
    assert_equal "bar", embed.foo
  end

  test "respond_to_missing? returns true for any method" do
    embed = Aven::Item::Embed.new({})
    assert embed.respond_to?(:any_method)
    assert embed.respond_to?(:any_method=)
  end
end
