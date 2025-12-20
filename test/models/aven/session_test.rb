# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_sessions
#
#  id             :bigint           not null, primary key
#  ip_address     :string
#  last_active_at :datetime
#  user_agent     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_aven_sessions_on_updated_at  (updated_at)
#  index_aven_sessions_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => aven_users.id)
#
require "test_helper"

class Aven::SessionTest < ActiveSupport::TestCase
  # Associations
  test "belongs to user" do
    session = aven_sessions(:one)
    assert_respond_to session, :user
    assert_instance_of Aven::User, session.user
  end

  # Validations
  test "requires user" do
    session = Aven::Session.new(
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    assert_not session.valid?
    assert_includes session.errors[:user], "must exist"
  end

  test "valid with all attributes" do
    user = aven_users(:one)
    session = Aven::Session.new(
      user: user,
      ip_address: "127.0.0.1",
      user_agent: "Test Agent",
      last_active_at: Time.current
    )

    assert session.valid?
  end

  # Scopes
  test "recent scope orders by last_active_at desc" do
    sessions = Aven::Session.recent
    assert_equal sessions.first.last_active_at, sessions.maximum(:last_active_at)
  end

  test "active scope returns sessions active within 30 days" do
    active_sessions = Aven::Session.active

    active_sessions.each do |session|
      assert session.last_active_at > 30.days.ago
    end
  end

  test "inactive scope returns sessions older than 30 days" do
    inactive_sessions = Aven::Session.inactive

    inactive_sessions.each do |session|
      assert(session.last_active_at.nil? || session.last_active_at <= 30.days.ago)
    end
  end

  # Activity tracking
  test "touch_activity! updates last_active_at" do
    session = aven_sessions(:one)
    session.update_column(:last_active_at, 1.hour.ago)

    freeze_time do
      session.touch_activity!
      assert_equal Time.current, session.reload.last_active_at
    end
  end

  test "touch_activity! is throttled within 5 minutes" do
    session = aven_sessions(:one)
    session.update_column(:last_active_at, 2.minutes.ago)

    original_time = session.last_active_at
    session.touch_activity!

    # Should not have changed because it was touched less than 5 minutes ago
    assert_equal original_time.to_i, session.reload.last_active_at.to_i
  end

  test "should_touch_activity? returns true when nil" do
    session = aven_sessions(:one)
    session.last_active_at = nil

    assert session.should_touch_activity?
  end

  test "should_touch_activity? returns true when older than 5 minutes" do
    session = aven_sessions(:one)
    session.last_active_at = 10.minutes.ago

    assert session.should_touch_activity?
  end

  test "should_touch_activity? returns false when within 5 minutes" do
    session = aven_sessions(:one)
    session.last_active_at = 2.minutes.ago

    assert_not session.should_touch_activity?
  end

  # Device info parsing
  test "device_info returns Mac for Mac OS X user agent" do
    session = aven_sessions(:one)
    session.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"

    assert_equal "Mac", session.device_info
  end

  test "device_info returns iPhone for iPhone user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)")

    assert_equal "iPhone", session.device_info
  end

  test "device_info returns iPad for iPad user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 (iPad; CPU OS 17_0)")

    assert_equal "iPad", session.device_info
  end

  test "device_info returns Android for Android user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 (Linux; Android 14)")

    assert_equal "Android", session.device_info
  end

  test "device_info returns Windows for Windows user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

    assert_equal "Windows", session.device_info
  end

  test "device_info returns Linux for Linux user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 (X11; Linux x86_64)")

    assert_equal "Linux", session.device_info
  end

  test "device_info returns Unknown device for blank user agent" do
    session = Aven::Session.new(user_agent: nil)

    assert_equal "Unknown device", session.device_info
  end

  # Browser info parsing
  test "browser_info returns Chrome for Chrome user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 Chrome/120.0.0.0")

    assert_equal "Chrome", session.browser_info
  end

  test "browser_info returns Firefox for Firefox user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 Firefox/120.0")

    assert_equal "Firefox", session.browser_info
  end

  test "browser_info returns Safari for Safari user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 Safari/604.1")

    assert_equal "Safari", session.browser_info
  end

  test "browser_info returns Edge for Edge user agent" do
    session = Aven::Session.new(user_agent: "Mozilla/5.0 Edge/120.0.0.0")

    assert_equal "Edge", session.browser_info
  end

  test "browser_info returns Unknown browser for blank user agent" do
    session = Aven::Session.new(user_agent: nil)

    assert_equal "Unknown browser", session.browser_info
  end

  # User association
  test "user can have multiple sessions" do
    user = aven_users(:one)
    initial_count = user.sessions.count

    user.sessions.create!(
      ip_address: "1.2.3.4",
      user_agent: "New Session",
      last_active_at: Time.current
    )

    assert_equal initial_count + 1, user.sessions.count
  end

  test "destroying user destroys associated sessions" do
    user = Aven::User.create!(email: "delete@test.com", auth_tenant: "test")
    session = user.sessions.create!(ip_address: "1.2.3.4", user_agent: "Test")
    session_id = session.id

    user.destroy

    assert_nil Aven::Session.find_by(id: session_id)
  end
end
