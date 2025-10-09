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
    devise(
      :omniauthable,
      omniauth_providers: Aven.configuration.auth.providers.map { |p| p[:provider] }
    )

    has_many :workspace_users, dependent: :destroy
    has_many :workspaces, through: :workspace_users
    has_many :workspace_user_roles, through: :workspace_users
    has_many :workspace_roles, through: :workspace_user_roles

    # has_many(:repos, class_name: UserRepo.name)
    # has_many(:deployments)
    # has_many(:strategies, foreign_key: :author_id, inverse_of: :author)
    # has_many(:credentials, class_name: ProviderCredential.name)

    validates :email, presence: true, uniqueness: { scope: :auth_tenant, case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :remote_id, uniqueness: { scope: :auth_tenant, case_sensitive: false }, allow_blank: true

    encrypts(:access_token)

    def self.create_from_omniauth!(request_env, auth_tenant)
      user = request_env.dig("omniauth.auth")
      remote_id = user["uid"]
      email = user.dig("info", "email") || "#{SecureRandom.uuid}@aven.dev"

      u = where(auth_tenant:, remote_id:).or(
        where(auth_tenant:, email:)
      ).first_or_initialize

      u.auth_tenant = auth_tenant
      u.remote_id = remote_id
      u.email = email
      u.access_token = user.dig("credentials", "token")
      u.save!

      u
    end
  end
end
