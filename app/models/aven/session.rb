# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_sessions
#
#  id             :bigint           not null, primary key
#  ip_address     :string
#  user_agent     :string
#  last_active_at :datetime
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
module Aven
  class Session < ApplicationRecord
    self.table_name = "aven_sessions"

    belongs_to :user, class_name: "Aven::User"

    validates :user, presence: true

    scope :recent, -> { order(last_active_at: :desc, updated_at: :desc) }
    scope :active, -> { where("last_active_at > ?", 30.days.ago) }
    scope :inactive, -> { where("last_active_at <= ? OR last_active_at IS NULL", 30.days.ago) }

    # Touch last_active_at on each authenticated request
    def touch_activity!
      update_column(:last_active_at, Time.current) if should_touch_activity?
    end

    # Prevent hammering the DB on every request - only update every 5 minutes
    def should_touch_activity?
      last_active_at.nil? || last_active_at < 5.minutes.ago
    end

    # Device info parsed from user_agent for display
    def device_info
      return "Unknown device" if user_agent.blank?

      # Basic parsing - could be enhanced with a gem like browser
      case user_agent
      when /iPhone/i then "iPhone"
      when /iPad/i then "iPad"
      when /Android/i then "Android"
      when /Mac OS X/i then "Mac"
      when /Windows/i then "Windows"
      when /Linux/i then "Linux"
      else "Unknown device"
      end
    end

    # Browser info parsed from user_agent for display
    def browser_info
      return "Unknown browser" if user_agent.blank?

      case user_agent
      when /Chrome/i then "Chrome"
      when /Firefox/i then "Firefox"
      when /Safari/i then "Safari"
      when /Edge/i then "Edge"
      when /Opera/i then "Opera"
      else "Unknown browser"
      end
    end
  end
end
