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
require "test_helper"

class Aven::WorkspaceTest < ActiveSupport::TestCase
  # Associations
  test "has many workspace_users" do
    workspace = aven_workspaces(:one)
    assert_respond_to workspace, :workspace_users
  end

  test "has many users through workspace_users" do
    workspace = aven_workspaces(:one)
    assert_respond_to workspace, :users
  end

  test "has many workspace_roles" do
    workspace = aven_workspaces(:one)
    assert_respond_to workspace, :workspace_roles
  end

  test "has many workspace_user_roles through workspace_roles" do
    workspace = aven_workspaces(:one)
    assert_respond_to workspace, :workspace_user_roles
  end

  # Validations
  test "validates uniqueness of slug when present" do
    workspace1 = aven_workspaces(:one)
    workspace2 = Aven::Workspace.new(label: "Test", slug: workspace1.slug)
    assert_not workspace2.valid?
    assert_includes workspace2.errors[:slug], "has already been taken"
  end

  test "allows blank slug" do
    workspace = Aven::Workspace.new(label: "Test", slug: nil)
    workspace.valid?
    # Slug should be generated from label
    assert_not_nil workspace.slug
  end

  test "validates length of label is at most 255" do
    workspace = Aven::Workspace.new(label: "a" * 256)
    assert_not workspace.valid?
    assert_includes workspace.errors[:label], "is too long (maximum is 255 characters)"
  end

  test "validates length of description is at most 1000" do
    workspace = Aven::Workspace.new(description: "a" * 1001)
    assert_not workspace.valid?
    assert_includes workspace.errors[:description], "is too long (maximum is 1000 characters)"
  end

  # Callbacks
  test "generates slug from label when blank" do
    workspace = Aven::Workspace.new(label: "My Cool Space", slug: nil)
    workspace.valid?
    assert_equal "my-cool-space", workspace.slug
  end

  # Tenant model registry
  test "tenant_models returns an array of registered tenant model classes" do
    tenant_models = Aven::Workspace.tenant_models
    assert_kind_of Array, tenant_models
    assert_includes tenant_models, TestProject
  end

  test "tenant_model_names returns class names of registered tenant models" do
    names = Aven::Workspace.tenant_model_names
    assert_kind_of Array, names
    assert names.all? { |name| name.is_a?(String) }
    assert_includes names, "TestProject"
  end

  test "register_tenant_model registers the model class" do
    assert_includes Aven::Workspace.tenant_models, TestProject
  end

  test "register_tenant_model defines query method on workspace instance" do
    workspace = aven_workspaces(:one)
    assert_respond_to workspace, :test_projects
  end

  test "register_tenant_model returns ActiveRecord::Relation for tenant model" do
    workspace = aven_workspaces(:one)
    assert_kind_of ActiveRecord::Relation, workspace.test_projects
  end

  test "find_tenant_record finds record in workspace" do
    workspace = aven_workspaces(:one)
    project = TestProject.create!(name: "Test", workspace: workspace)

    found = workspace.find_tenant_record("TestProject", project.id)
    assert_equal project, found
  end

  test "find_tenant_record returns nil for non-existent model" do
    workspace = aven_workspaces(:one)
    result = workspace.find_tenant_record("NonExistent", 123)
    assert_nil result
  end

  test "destroy_tenant_data destroys all tenant records for workspace" do
    workspace1 = Aven::Workspace.create!(label: "Workspace 1")
    workspace2 = Aven::Workspace.create!(label: "Workspace 2")

    project1 = TestProject.create!(name: "Project 1", workspace: workspace1)
    project2 = TestProject.create!(name: "Project 2", workspace: workspace2)

    workspace1.destroy_tenant_data

    assert_not TestProject.exists?(project1.id)
    assert TestProject.exists?(project2.id)
  end

  test "dynamic query methods provide query method for tenant models" do
    workspace = aven_workspaces(:one)
    project1 = TestProject.create!(name: "Project 1", workspace: workspace)
    project2 = TestProject.create!(name: "Project 2", workspace: workspace)

    projects = workspace.test_projects
    assert_equal 2, projects.count
    assert_includes projects, project1
    assert_includes projects, project2
  end

  test "dynamic query methods scope queries to workspace" do
    workspace = aven_workspaces(:one)
    other_workspace = aven_workspaces(:two)

    project = TestProject.create!(name: "Project", workspace: workspace)
    other_project = TestProject.create!(name: "Other", workspace: other_workspace)

    assert_not_includes workspace.test_projects, other_project
  end
end
