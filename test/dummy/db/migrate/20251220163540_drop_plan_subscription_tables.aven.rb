# frozen_string_literal: true

# This migration comes from aven (originally 20200101000045)
class DropPlanSubscriptionTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :aven_workspace_features, if_exists: true
    drop_table :aven_feature_usages, if_exists: true
    drop_table :aven_subscriptions, if_exists: true
    drop_table :aven_plan_features, if_exists: true
    drop_table :aven_plans, if_exists: true
  end
end
