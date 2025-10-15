require "rails_helper"

RSpec.describe Aven::Model::TenantModel, type: :model do
  # Use dummy app models
  let(:workspace) { create(:aven_workspace) }
  let(:project) { TestProject.create!(name: "Test Project", workspace:) }

  describe "included behavior" do
    it "adds belongs_to :workspace association" do
      expect(TestProject.reflect_on_association(:workspace)).to be_present
      expect(TestProject.reflect_on_association(:workspace).class_name).to eq("Aven::Workspace")
    end

    it "registers model with Aven::Workspace" do
      expect(Aven::Workspace.tenant_models).to include(TestProject)
    end

    it "adds in_workspace scope" do
      expect(TestProject).to respond_to(:in_workspace)
    end

    it "adds for_workspace scope" do
      expect(TestProject).to respond_to(:for_workspace)
    end
  end

  describe "#workspace_tenant_id" do
    it "returns class name combined with workspace_id" do
      expect(project.workspace_tenant_id).to eq("TestProject;#{workspace.id}")
    end
  end

  describe "#workspace_scoped?" do
    it "returns true" do
      expect(project.workspace_scoped?).to be true
    end
  end

  describe "#workspace_association_name" do
    it "returns the pluralized association name" do
      expect(project.workspace_association_name).to eq(:test_projects)
    end
  end

  describe ".workspace_optional!" do
    it "makes workspace association optional" do
      expect(TestResource.reflect_on_association(:workspace).options[:optional]).to be true
    end
  end

  describe ".workspace_association_name" do
    it "returns pluralized symbol of class name" do
      expect(TestProject.workspace_association_name).to eq(:test_projects)
    end
  end

  describe "scopes" do
    let!(:workspace1) { create(:aven_workspace) }
    let!(:workspace2) { create(:aven_workspace) }
    let!(:project1) { TestProject.create!(name: "Project 1", workspace: workspace1) }
    let!(:project2) { TestProject.create!(name: "Project 2", workspace: workspace2) }

    describe ".in_workspace" do
      it "returns only models in the given workspace" do
        results = TestProject.in_workspace(workspace1)
        expect(results).to include(project1)
        expect(results).not_to include(project2)
      end
    end

    describe ".for_workspace" do
      it "returns only models for the given workspace" do
        results = TestProject.for_workspace(workspace2)
        expect(results).to include(project2)
        expect(results).not_to include(project1)
      end
    end
  end
end
