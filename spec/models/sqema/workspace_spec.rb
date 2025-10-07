require "rails_helper"

RSpec.describe Sqema::Workspace, type: :model do
  describe "associations" do
    it { should have_many(:workspace_users).class_name("Sqema::WorkspaceUser").dependent(:destroy) }
    it { should have_many(:users).through(:workspace_users).class_name("Sqema::User") }
    it { should have_many(:workspace_roles).class_name("Sqema::WorkspaceRole").dependent(:destroy) }
    it { should have_many(:workspace_user_roles).through(:workspace_roles).class_name("Sqema::WorkspaceUserRole") }
  end

  describe "validations" do
    it { should validate_uniqueness_of(:slug).allow_blank }
    it { should validate_length_of(:label).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe "callbacks" do
    it "generates slug from label when blank" do
      workspace = build(:sqema_workspace, label: "My Cool Space", slug: nil)
      workspace.valid?
      expect(workspace.slug).to eq("my-cool-space")
    end
  end
end

