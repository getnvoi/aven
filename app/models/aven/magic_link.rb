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
module Aven
  class MagicLink < ApplicationRecord
    self.table_name = "aven_magic_links"

    # Default expiration time for magic links
    EXPIRATION_TIME = 15.minutes

    # Character set for code generation (avoids confusing characters: O, I, L)
    CODE_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".freeze
    CODE_LENGTH = 6

    # Character substitutions for user input normalization
    CODE_SUBSTITUTIONS = { "O" => "0", "I" => "1", "L" => "1" }.freeze

    belongs_to :user, class_name: "Aven::User"

    enum :purpose, { sign_in: 0, sign_up: 1 }

    validates :code, presence: true, uniqueness: true
    validates :purpose, presence: true
    validates :expires_at, presence: true

    before_validation :generate_code, on: :create
    before_validation :set_expiration, on: :create

    scope :active, -> { where("expires_at > ?", Time.current) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }
    scope :recent, -> { order(created_at: :desc) }

    class << self
      # Find and consume a magic link by code
      # Returns the magic link if valid and active, nil otherwise
      # Destroys the link after consumption (one-time use)
      #
      # @param code [String] the code to look up
      # @return [MagicLink, nil] the magic link or nil if not found/expired
      def consume(code)
        normalized = normalize_code(code)
        return nil if normalized.blank?

        magic_link = active.find_by(code: normalized)
        return nil unless magic_link

        magic_link.tap(&:destroy)
      end

      # Normalize user input code (handle common substitutions)
      #
      # @param code [String] the raw user input
      # @return [String] the normalized code
      def normalize_code(code)
        return "" if code.blank?

        normalized = code.to_s.strip.upcase
        CODE_SUBSTITUTIONS.each do |from, to|
          normalized = normalized.gsub(from, to)
        end
        normalized
      end

      # Generate a unique code
      #
      # @return [String] a unique 6-character code
      def generate_unique_code
        loop do
          code = CODE_LENGTH.times.map { CODE_ALPHABET[SecureRandom.random_number(CODE_ALPHABET.length)] }.join
          break code unless exists?(code: code)
        end
      end

      # Clean up expired magic links
      #
      # @return [Integer] number of deleted records
      def cleanup_expired
        expired.delete_all
      end
    end

    # Check if the magic link is still active (not expired)
    #
    # @return [Boolean] true if active
    def active?
      expires_at > Time.current
    end

    # Check if the magic link has expired
    #
    # @return [Boolean] true if expired
    def expired?
      !active?
    end

    # Time remaining until expiration
    #
    # @return [ActiveSupport::Duration] time remaining
    def time_remaining
      return 0.seconds if expired?

      (expires_at - Time.current).seconds
    end

    private

      def generate_code
        self.code ||= self.class.generate_unique_code
      end

      def set_expiration
        self.expires_at ||= EXPIRATION_TIME.from_now
      end
  end
end
