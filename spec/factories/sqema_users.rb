FactoryBot.define do
  factory :sqema_user, class: "Sqema::User" do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    auth_tenant { "test" }
    encrypted_password { "" }
  end
end

