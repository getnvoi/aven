# == Schema Information
#
# Table name: test_resources
#
#  id           :bigint           not null, primary key
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  workspace_id :bigint
#
# Indexes
#
#  index_test_resources_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
class TestResource < ApplicationRecord
  include Aven::Model::TenantModel
  workspace_optional!
end
