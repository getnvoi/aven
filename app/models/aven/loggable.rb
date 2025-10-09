module Aven
  module Loggable
    def log!(message:, level: "info", metadata: nil, **extra)
      attrs = {
        message: message,
        level: level,
        metadata: metadata || {}
      }

      ws = is_a?(Aven::Workspace) ? self : workspace
      attrs[:workspace] = ws

      attrs[:run_id] = extra[:run_id] if extra.key?(:run_id)
      attrs[:state] = extra[:state] if extra.key?(:state)
      attrs[:state_machine] = extra[:state_machine] if extra.key?(:state_machine)

      logs.create!(attrs)
    end
  end
end

