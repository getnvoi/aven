class TestResource < ApplicationRecord
  include Aven::Model::TenantModel
  workspace_optional!
end
