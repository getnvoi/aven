# frozen_string_literal: true

module Aven
  # Thread-safe request context using ActiveSupport::CurrentAttributes.
  # Provides access to the current session, user, workspace, and request metadata.
  #
  # @example Accessing the current user
  #   Aven::Current.user # => Aven::User or nil
  #
  # @example Scoped execution with a workspace
  #   Aven::Current.with_workspace(workspace) do
  #     # Code here has Current.workspace set
  #   end
  #
  class Current < ActiveSupport::CurrentAttributes
    # Core authentication attributes
    attribute :session    # Aven::Session (DB-backed)
    attribute :workspace  # Aven::Workspace

    # Request metadata for audit/security
    attribute :user_agent, :ip_address, :request_id

    # Delegate user lookup to the session
    delegate :user, to: :session, allow_nil: true

    # Auto-resolve workspace when session is set (if only one workspace)
    def session=(value)
      super(value)

      if value.present? && workspace.blank? && value.user.present?
        workspaces = value.user.workspaces
        self.workspace = workspaces.first if workspaces.one?
      end
    end

    # Execute a block with a specific workspace context
    #
    # @param ws [Aven::Workspace] the workspace to use
    # @yield the block to execute with the workspace context
    def with_workspace(ws, &block)
      with(workspace: ws, &block)
    end

    # Execute a block without any workspace context
    #
    # @yield the block to execute without workspace
    def without_workspace(&block)
      with(workspace: nil, &block)
    end

    # Check if there is an authenticated session
    #
    # @return [Boolean] true if a valid session exists
    def authenticated?
      session.present? && user.present?
    end

    # Check if there is a workspace context
    #
    # @return [Boolean] true if a workspace is set
    def workspace?
      workspace.present?
    end
  end
end
