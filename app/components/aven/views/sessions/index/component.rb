# frozen_string_literal: true

module Aven::Views::Sessions::Index
  class Component < Aven::ApplicationViewComponent
    option :sessions
    option :current_session_id, optional: true

    def revoke_path(session)
      Aven::Engine.routes.url_helpers.session_path(session)
    end

    def revoke_all_path
      Aven::Engine.routes.url_helpers.revoke_all_sessions_path
    end

    def current_session?(session)
      session.id == current_session_id
    end

    def time_ago(time)
      return "Never" unless time

      distance = Time.current - time
      case distance
      when 0..59 then "Just now"
      when 60..3599 then "#{(distance / 60).to_i} minutes ago"
      when 3600..86399 then "#{(distance / 3600).to_i} hours ago"
      else "#{(distance / 86400).to_i} days ago"
      end
    end

    def has_other_sessions?
      sessions.any? { |s| !current_session?(s) }
    end
  end
end
