# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_magic_links
#
#  id         :bigint           not null, primary key
#  code       :string           not null
#  expires_at :datetime         not null
#  purpose    :integer          default("sign_in"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_aven_magic_links_on_code        (code) UNIQUE
#  index_aven_magic_links_on_expires_at  (expires_at)
#  index_aven_magic_links_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => aven_users.id)
#
require "test_helper"

class Aven::MagicLinkTest < ActiveSupport::TestCase
  # Associations
  test "belongs to user" do
    magic_link = aven_magic_links(:active_sign_in)
    assert_respond_to magic_link, :user
    assert_instance_of Aven::User, magic_link.user
  end

  # Validations
  test "requires user" do
    magic_link = Aven::MagicLink.new(
      code: "ABC123",
      purpose: :sign_in,
      expires_at: 15.minutes.from_now
    )

    assert_not magic_link.valid?
    assert_includes magic_link.errors[:user], "must exist"
  end

  test "requires code" do
    user = aven_users(:one)
    magic_link = Aven::MagicLink.new(
      user: user,
      code: nil,
      purpose: :sign_in,
      expires_at: 15.minutes.from_now
    )
    magic_link.valid?
    
    # Code is auto-generated before validation
    assert magic_link.code.present?
  end

  test "code must be unique" do
    existing = aven_magic_links(:active_sign_in)
    user = aven_users(:two)
    
    magic_link = Aven::MagicLink.new(
      user: user,
      code: existing.code,
      purpose: :sign_in,
      expires_at: 15.minutes.from_now
    )

    assert_not magic_link.valid?
    assert_includes magic_link.errors[:code], "has already been taken"
  end

  # Enums
  test "purpose enum" do
    magic_link = Aven::MagicLink.new
    
    assert_respond_to magic_link, :sign_in?
    assert_respond_to magic_link, :sign_up?
  end

  test "sign_in purpose" do
    magic_link = aven_magic_links(:active_sign_in)
    assert magic_link.sign_in?
  end

  test "sign_up purpose" do
    magic_link = aven_magic_links(:active_sign_up)
    assert magic_link.sign_up?
  end

  # Code generation
  test "auto-generates code on create" do
    user = aven_users(:one)
    magic_link = Aven::MagicLink.create!(user: user, purpose: :sign_in)

    assert magic_link.code.present?
    assert_equal 6, magic_link.code.length
  end

  test "generated code only contains allowed characters" do
    user = aven_users(:one)
    
    10.times do
      magic_link = Aven::MagicLink.create!(user: user, purpose: :sign_in)
      assert_match(/^[0-9A-HJ-NP-TV-Z]+$/, magic_link.code)
    end
  end

  test "auto-sets expiration on create" do
    user = aven_users(:one)
    
    freeze_time do
      magic_link = Aven::MagicLink.create!(user: user, purpose: :sign_in)
      expected_expiry = Aven::MagicLink::EXPIRATION_TIME.from_now
      
      assert_equal expected_expiry.to_i, magic_link.expires_at.to_i
    end
  end

  # Scopes
  test "active scope returns non-expired links" do
    active_links = Aven::MagicLink.active

    active_links.each do |link|
      assert link.expires_at > Time.current
    end
  end

  test "expired scope returns expired links" do
    expired_links = Aven::MagicLink.expired

    expired_links.each do |link|
      assert link.expires_at <= Time.current
    end
  end

  # Consume
  test "consume returns magic link and destroys it" do
    magic_link = aven_magic_links(:active_sign_in)
    code = magic_link.code
    
    result = Aven::MagicLink.consume(code)

    assert_equal magic_link.user, result.user
    assert_nil Aven::MagicLink.find_by(code: code)
  end

  test "consume returns nil for expired links" do
    expired_link = aven_magic_links(:expired)
    
    result = Aven::MagicLink.consume(expired_link.code)

    assert_nil result
  end

  test "consume returns nil for non-existent codes" do
    result = Aven::MagicLink.consume("NOTREAL")

    assert_nil result
  end

  test "consume returns nil for blank code" do
    assert_nil Aven::MagicLink.consume("")
    assert_nil Aven::MagicLink.consume(nil)
  end

  # Code normalization
  test "normalize_code handles lowercase" do
    assert_equal "ABC123", Aven::MagicLink.normalize_code("abc123")
  end

  test "normalize_code handles whitespace" do
    assert_equal "ABC123", Aven::MagicLink.normalize_code("  abc123  ")
  end

  test "normalize_code substitutes O for 0" do
    assert_equal "0BC123", Aven::MagicLink.normalize_code("OBC123")
  end

  test "normalize_code substitutes I for 1" do
    assert_equal "1BC123", Aven::MagicLink.normalize_code("IBC123")
  end

  test "normalize_code substitutes L for 1" do
    assert_equal "1BC123", Aven::MagicLink.normalize_code("LBC123")
  end

  test "consume works with normalized input" do
    magic_link = aven_magic_links(:active_sign_in)
    code = magic_link.code.downcase  # lowercase version
    
    result = Aven::MagicLink.consume(code)

    assert_equal magic_link.user, result.user
  end

  # Active/expired checks
  test "active? returns true for non-expired link" do
    magic_link = aven_magic_links(:active_sign_in)
    assert magic_link.active?
  end

  test "active? returns false for expired link" do
    magic_link = aven_magic_links(:expired)
    assert_not magic_link.active?
  end

  test "expired? returns false for active link" do
    magic_link = aven_magic_links(:active_sign_in)
    assert_not magic_link.expired?
  end

  test "expired? returns true for expired link" do
    magic_link = aven_magic_links(:expired)
    assert magic_link.expired?
  end

  # Time remaining
  test "time_remaining returns positive duration for active link" do
    magic_link = aven_magic_links(:active_sign_in)
    assert magic_link.time_remaining > 0
  end

  test "time_remaining returns zero for expired link" do
    magic_link = aven_magic_links(:expired)
    assert_equal 0.seconds, magic_link.time_remaining
  end

  # Cleanup
  test "cleanup_expired removes only expired links" do
    active_count_before = Aven::MagicLink.active.count
    expired_count_before = Aven::MagicLink.expired.count
    
    deleted_count = Aven::MagicLink.cleanup_expired

    assert_equal expired_count_before, deleted_count
    assert_equal active_count_before, Aven::MagicLink.active.count
    assert_equal 0, Aven::MagicLink.expired.count
  end

  # User association
  test "destroying user destroys associated magic links" do
    user = Aven::User.create!(email: "magic@test.com", auth_tenant: "test")
    magic_link = user.magic_links.create!(purpose: :sign_in)
    link_id = magic_link.id

    user.destroy

    assert_nil Aven::MagicLink.find_by(id: link_id)
  end
end
