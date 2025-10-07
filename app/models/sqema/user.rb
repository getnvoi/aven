# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  access_token           :string
#  admin                  :boolean          default(FALSE), not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  tenant                 :string           not null
#  username               :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  github_id              :string
#
# Indexes
#
#  index_users_on_email_and_tenant      (email,tenant) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
module Sqema
  class User < ApplicationRecord
    devise(:omniauthable, omniauth_providers: %i[google_oauth2 github])
    has_many :workspace_users, dependent: :destroy
    has_many :workspaces, through: :workspace_users
    has_many :workspace_user_roles, through: :workspace_users
    has_many :workspace_roles, through: :workspace_user_roles

    # has_many(:repos, class_name: UserRepo.name)
    # has_many(:deployments)
    # has_many(:strategies, foreign_key: :author_id, inverse_of: :author)
    # has_many(:credentials, class_name: ProviderCredential.name)

    validates :email, presence: true, uniqueness: { scope: :auth_tenant, case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :username, presence: true, uniqueness: { scope: :auth_tenant }
    validates :remote_id, uniqueness: { scope: :auth_tenant, case_sensitive: false }, allow_blank: true

    encrypts(:access_token)

    before_validation do
      self.username = generate_unique_username if username.blank?
    end

    def self.create_from_omniauth!(request_env, auth_tenant)
      user = request_env.dig("omniauth.auth")
      remote_id = user["uid"]
      email = user.dig("info", "email") || "#{SecureRandom.uuid}@sqema.dev"

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

    private

      def generate_unique_username
        loop do
          username = [ RandomUsername.adjective, RandomUsername.noun ].join("-")
          return username unless Sqema::User.exists?(username:)
        end
      end
  end
end
