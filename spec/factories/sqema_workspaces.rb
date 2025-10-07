FactoryBot.define do
  factory :sqema_workspace, class: "Sqema::Workspace" do
    sequence(:label) { |n| "Workspace #{n}" }
    description { "A test workspace" }
    domain { "example.com" }
  end
end

