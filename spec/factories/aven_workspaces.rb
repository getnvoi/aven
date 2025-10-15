# == Schema Information
#
# Table name: aven_workspaces
#
#  id          :bigint           not null, primary key
#  description :text
#  domain      :string
#  label       :string
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_aven_workspaces_on_slug  (slug) UNIQUE
#
FactoryBot.define do
  factory :aven_workspace, class: "Aven::Workspace" do
    sequence(:label) { |n| "Workspace #{n}" }
    description { "A test workspace" }
    domain { "example.com" }
  end
end
