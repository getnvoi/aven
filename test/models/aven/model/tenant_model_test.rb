require "test_helper"

class Aven::Model::TenantModelTest < ActiveSupport::TestCase
  # Included behavior
  test "adds belongs_to workspace association" do
    association = TestProject.reflect_on_association(:workspace)
    assert_not_nil association
    assert_equal "Aven::Workspace", association.class_name
  end

  test "registers model with Aven::Workspace" do
    assert_includes Aven::Workspace.tenant_models, TestProject
  end

  test "adds in_workspace scope" do
    assert_respond_to TestProject, :in_workspace
  end

  test "adds for_workspace scope" do
    assert_respond_to TestProject, :for_workspace
  end

  # Instance methods
  test "workspace_tenant_id returns class name combined with workspace_id" do
    workspace = aven_workspaces(:one)
    project = TestProject.create!(name: "Test Project", workspace: workspace)

    assert_equal "TestProject;#{workspace.id}", project.workspace_tenant_id
  end

  test "workspace_scoped? returns true" do
    workspace = aven_workspaces(:one)
    project = TestProject.create!(name: "Test Project", workspace: workspace)

    assert project.workspace_scoped?
  end

  test "workspace_association_name returns the pluralized association name" do
    workspace = aven_workspaces(:one)
    project = TestProject.create!(name: "Test Project", workspace: workspace)

    assert_equal :test_projects, project.workspace_association_name
  end

  # Class methods
  test "workspace_optional! makes workspace association optional" do
    assert TestResource.reflect_on_association(:workspace).options[:optional]
  end

  test "workspace_association_name returns pluralized symbol of class name" do
    assert_equal :test_projects, TestProject.workspace_association_name
  end

  # Scopes
  test "in_workspace returns only models in the given workspace" do
    workspace1 = Aven::Workspace.create!(label: "Workspace 1")
    workspace2 = Aven::Workspace.create!(label: "Workspace 2")
    project1 = TestProject.create!(name: "Project 1", workspace: workspace1)
    project2 = TestProject.create!(name: "Project 2", workspace: workspace2)

    results = TestProject.in_workspace(workspace1)
    assert_includes results, project1
    assert_not_includes results, project2
  end

  test "for_workspace returns only models for the given workspace" do
    workspace1 = Aven::Workspace.create!(label: "Workspace 1")
    workspace2 = Aven::Workspace.create!(label: "Workspace 2")
    project1 = TestProject.create!(name: "Project 1", workspace: workspace1)
    project2 = TestProject.create!(name: "Project 2", workspace: workspace2)

    results = TestProject.for_workspace(workspace2)
    assert_includes results, project2
    assert_not_includes results, project1
  end
end
