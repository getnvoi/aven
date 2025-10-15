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

  describe "tenant model registry" do
    describe ".tenant_models" do
      it "returns an array of registered tenant model classes" do
        expect(Aven::Workspace.tenant_models).to be_an(Array)
        expect(Aven::Workspace.tenant_models).to include(TestProject)
      end
    end

    describe ".tenant_model_names" do
      it "returns class names of registered tenant models" do
        names = Aven::Workspace.tenant_model_names
        expect(names).to be_an(Array)
        expect(names).to all(be_a(String))
        expect(names).to include("TestProject")
      end
    end

    describe ".register_tenant_model" do
      it "registers the model class" do
        expect(Aven::Workspace.tenant_models).to include(TestProject)
      end

      it "defines query method on workspace instance" do
        workspace = create(:aven_workspace)
        expect(workspace).to respond_to(:test_projects)
      end

      it "returns ActiveRecord::Relation for tenant model" do
        workspace = create(:aven_workspace)
        expect(workspace.test_projects).to be_a(ActiveRecord::Relation)
      end
    end

    describe "#find_tenant_record" do
      let(:workspace) { create(:aven_workspace) }
      let(:project) { TestProject.create!(name: "Test", workspace:) }

      it "finds record in workspace" do
        found = workspace.find_tenant_record("TestProject", project.id)
        expect(found).to eq(project)
      end

      it "returns nil for non-existent model" do
        result = workspace.find_tenant_record("NonExistent", 123)
        expect(result).to be_nil
      end
    end

    describe "#destroy_tenant_data" do
      it "destroys all tenant records for workspace" do
        workspace1 = create(:aven_workspace)
        workspace2 = create(:aven_workspace)

        project1 = TestProject.create!(name: "Project 1", workspace: workspace1)
        project2 = TestProject.create!(name: "Project 2", workspace: workspace2)

        workspace1.destroy_tenant_data

        expect(TestProject.exists?(project1.id)).to be false
        expect(TestProject.exists?(project2.id)).to be true
      end
    end

    describe "dynamic query methods" do
      let(:workspace) { create(:aven_workspace) }
      let!(:project1) { TestProject.create!(name: "Project 1", workspace:) }
      let!(:project2) { TestProject.create!(name: "Project 2", workspace:) }

      it "provides query method for tenant models" do
        projects = workspace.test_projects
        expect(projects.count).to eq(2)
        expect(projects).to include(project1, project2)
      end

      it "scopes queries to workspace" do
        other_workspace = create(:aven_workspace)
        other_project = TestProject.create!(name: "Other", workspace: other_workspace)

        expect(workspace.test_projects).not_to include(other_project)
      end
    end
  end
end
