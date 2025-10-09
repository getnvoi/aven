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
require "rails_helper"

RSpec.describe Aven::Workspace, type: :model do
  describe "associations" do
    it { should have_many(:workspace_users).class_name("Aven::WorkspaceUser").dependent(:destroy) }
    it { should have_many(:users).through(:workspace_users).class_name("Aven::User") }
    it { should have_many(:workspace_roles).class_name("Aven::WorkspaceRole").dependent(:destroy) }
    it { should have_many(:workspace_user_roles).through(:workspace_roles).class_name("Aven::WorkspaceUserRole") }
  end

  describe "validations" do
    it { should validate_uniqueness_of(:slug).allow_blank }
    it { should validate_length_of(:label).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe "callbacks" do
    it "generates slug from label when blank" do
      workspace = build(:aven_workspace, label: "My Cool Space", slug: nil)
      workspace.valid?
      expect(workspace.slug).to eq("my-cool-space")
    end
  end
end

