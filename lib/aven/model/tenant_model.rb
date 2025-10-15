module Aven
  module Model
    # TenantModel provides workspace multi-tenancy support for ActiveRecord models.
    #
    # Usage:
    #   class Server < ApplicationRecord
    #     include Aven::TenantModel
    #   end
    #
    # This will:
    # - Add belongs_to :workspace association
    # - Validate workspace_id column exists
    # - Register model with Aven::Workspace
    # - Add workspace scoping helpers
    #
    # Inspired by Flipper's Model::ActiveRecord pattern.
    module TenantModel
      extend ActiveSupport::Concern

      included do
        # Validate workspace_id column exists at include time
        unless column_names.include?("workspace_id")
          raise ArgumentError,
            "#{name} includes Aven::TenantModel but does not have a workspace_id column. " \
            "Add a workspace_id column to #{table_name} first."
        end

        # Add belongs_to association if not already defined
        unless reflect_on_association(:workspace)
          belongs_to :workspace, class_name: "Aven::Workspace"
        end

        # Register this model as a tenant model
        Aven::Workspace.register_tenant_model(self)

        # Add scopes for workspace querying
        scope :in_workspace, ->(workspace) { where(workspace_id: workspace.id) }
        scope :for_workspace, ->(workspace) { where(workspace_id: workspace.id) }
      end

      # Returns a unique identifier combining class name and workspace_id
      # Useful for caching keys, logging, permissions, etc.
      #
      # Example:
      #   server.workspace_tenant_id #=> "Server;123"
      def workspace_tenant_id
        "#{self.class.base_class.name};#{workspace_id}"
      end

      # Check if this model is workspace-scoped
      def workspace_scoped?
        true
      end

      # Returns workspace association name for this model type
      def workspace_association_name
        self.class.workspace_association_name
      end

      module ClassMethods
        # Make workspace association optional
        # Call this in your model if workspace can be nil
        #
        # Example:
        #   class DnsCredential < ApplicationRecord
        #     include Aven::TenantModel
        #     workspace_optional!
        #   end
        def workspace_optional!
          _reflect_on_association(:workspace).options[:optional] = true
        end

        # Returns the association name that Workspace will use for this model
        # Example: Server => :servers, DnsCredential => :dns_credentials
        def workspace_association_name
          name.underscore.pluralize.to_sym
        end

        # Check if this model has a unique workspace constraint
        # Used to determine if Workspace should use has_one vs has_many
        def unique_per_workspace?
          return false unless table_exists?

          connection.indexes(table_name).any? { |idx|
            idx.unique && idx.columns == [ "workspace_id" ]
          }
        end
      end
    end
  end
end
