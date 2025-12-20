module Aven
  module InviteType
    FULFILLMENT = "fulfillment"
    JOIN_WORKSPACE = "join_workspace"
    JOIN_WORKSPACE_FULFILLMENT = "join_workspace_fulfillment"

    ALL = [
      FULFILLMENT,
      JOIN_WORKSPACE,
      JOIN_WORKSPACE_FULFILLMENT
    ].freeze

    def self.valid?(type)
      ALL.include?(type)
    end
  end
end
