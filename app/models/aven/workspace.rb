# == Schema Information
#
# Table name: aven_workspaces
#
#  id                :bigint           not null, primary key
#  description       :text
#  domain            :string
#  label             :string
#  onboarding_state  :string           default("pending")
#  slug              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  created_by_id     :bigint
#
# Indexes
#
#  index_aven_workspaces_on_created_by_id  (created_by_id)
#  index_aven_workspaces_on_slug           (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => aven_users.id)
#
module Aven
  class Workspace < ApplicationRecord
    include PgSearch::Model
    extend FriendlyId
    friendly_id :label, use: :slugged

    self.table_name = "aven_workspaces"

    belongs_to :created_by, class_name: "Aven::User"

    has_many :workspace_users, class_name: "Aven::WorkspaceUser", dependent: :destroy
    has_many :users, through: :workspace_users, class_name: "Aven::User"
    has_many :workspace_roles, class_name: "Aven::WorkspaceRole", dependent: :destroy
    has_many :workspace_user_roles, through: :workspace_roles, class_name: "Aven::WorkspaceUserRole"

    # Chat associations
    has_many :aven_chat_threads, class_name: "Aven::Chat::Thread", dependent: :destroy

    # Article associations
    has_many :aven_articles, class_name: "Aven::Article", dependent: :destroy

    # Feature associations
    has_many :feature_workspace_users, class_name: "Aven::FeatureWorkspaceUser", dependent: :destroy

    validates :slug, uniqueness: true, allow_blank: true
    validates :label, length: { maximum: 255 }, allow_blank: true
    validates :description, length: { maximum: 1000 }, allow_blank: true

    pg_search_scope :search,
      against: [:label, :slug, :description, :domain],
      using: {
        tsearch: { prefix: true }
      }

    # Tenant model registry (inspired by Flipper's group registry pattern)
    class << self
      # Returns array of all registered tenant model classes
      def tenant_models
        @tenant_models ||= []
      end

      # Register a model class as workspace-scoped
      # Called automatically when a model includes Aven::TenantModel
      def register_tenant_model(model_class)
        return if tenant_models.include?(model_class)

        tenant_models << model_class
        define_tenant_association(model_class)
      end

      # Get all registered tenant model class names
      def tenant_model_names
        tenant_models.map(&:name)
      end

      private

        # Define association method for a tenant model
        # Creates query method that returns ActiveRecord::Relation
        def define_tenant_association(model_class)
          association_name = model_class.workspace_association_name

          # Define instance method for querying tenant records
          define_method(association_name) do
            model_class.where(workspace_id: id)
          end
        end
    end

    # Find a tenant record by type and ID
    def find_tenant_record(model_name, record_id)
      model_class = self.class.tenant_models.find { |m| m.name == model_name }
      return nil unless model_class

      model_class.where(workspace_id: id).find(record_id)
    end

    # Destroy all tenant data for this workspace
    def destroy_tenant_data
      self.class.tenant_models.each do |model_class|
        model_class.where(workspace_id: id).destroy_all
      end
    end
  end
end
