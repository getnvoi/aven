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
FactoryBot.define do
  factory :aven_user, class: "Aven::User" do
    sequence(:email) { |n| "user#{n}@example.com" }
    auth_tenant { "test" }
    encrypted_password { "" }
  end
end

