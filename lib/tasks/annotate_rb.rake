# This rake task was added by annotate_rb gem.

# Can set `ANNOTATERB_SKIP_ON_DB_TASKS` to be anything to skip this
is_dummy = Rails.application.class.module_parent_name == "Dummy"

if Rails.env.development? && ENV["ANNOTATERB_SKIP_ON_DB_TASKS"].nil? && is_dummy
  require "annotate_rb"

  AnnotateRb::Core.load_rake_tasks
end
