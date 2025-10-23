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
  end
end
