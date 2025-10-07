ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

# Ensure engine and dummy app migrations are applied
ActiveRecord::Migrator.migrations_paths = [
  File.expand_path("../db/migrate", __dir__),
  File.expand_path("dummy/db/migrate", __dir__)
].uniq

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_active_record = true
  config.fixture_paths = [File.join(__dir__, "fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
end

# Ensure FactoryBot loads engine factories (engine root/spec/factories)
FactoryBot.factories.clear
FactoryBot.definition_file_paths = [File.join(__dir__, "factories")]
FactoryBot.find_definitions
