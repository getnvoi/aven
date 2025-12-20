# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_system_users
#
#  id                     :bigint           not null, primary key
#  email                  :string           not null
#  password_digest        :string           not null
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_aven_system_users_on_email                 (email) UNIQUE
#  index_aven_system_users_on_reset_password_token  (reset_password_token) UNIQUE
#
module Aven
  class SystemUser < ApplicationRecord
    self.table_name = "aven_system_users"

    # Password authentication (required for system users)
    has_secure_password

    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 12 }, if: :password_digest_changed?

    # Token generation for password reset
    generates_token_for :password_reset, expires_in: 20.minutes do
      password_salt&.last(10)
    end
  end
end
