# == Schema Information
#
# Table name: aven_users
#
#  id                     :bigint           not null, primary key
#  access_token           :string
#  admin                  :boolean          default(FALSE), not null
#  auth_tenant            :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  password_digest        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  remote_id              :string
#
# Indexes
#
#  index_aven_users_on_email_and_auth_tenant  (email,auth_tenant) UNIQUE
#  index_aven_users_on_reset_password_token   (reset_password_token) UNIQUE
#
module Aven
  class User < ApplicationRecord
    # Password authentication (optional - only validates when password is set)
    has_secure_password validations: false

    has_many :sessions, class_name: "Aven::Session", dependent: :destroy
    has_many :magic_links, class_name: "Aven::MagicLink", dependent: :destroy
    has_many :workspace_users, dependent: :destroy
    has_many :workspaces, through: :workspace_users
    has_many :workspace_user_roles, through: :workspace_users
    has_many :workspace_roles, through: :workspace_user_roles

    # Token generation for password reset
    generates_token_for :password_reset, expires_in: Aven.configuration.password_reset_expiry do
      password_salt&.last(10)
    end

    validates :email, presence: true, uniqueness: { scope: :auth_tenant, case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :remote_id, uniqueness: { scope: :auth_tenant, case_sensitive: false }, allow_blank: true

    # Password validation only when password is being set
    validates :password, length: {
      minimum: -> { Aven.configuration.password_minimum_length },
      message: ->(_, data) { "must be at least #{Aven.configuration.password_minimum_length} characters" }
    }, if: :password_digest_changed?

    encrypts(:access_token)

    # Check if user has a password set
    def password_set?
      password_digest.present?
    end

    # Invalidate all sessions except the current one (call after password change)
    def invalidate_other_sessions(current_session)
      sessions.where.not(id: current_session&.id).destroy_all
    end
  end
end
