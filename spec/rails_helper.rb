ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"
require "webmock/rspec"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

ActiveRecord::Migration.maintain_test_schema!

# Silence OmniAuth debug output
OmniAuth.config.logger = Logger.new("/dev/null")

RSpec.configure do |config|
  config.use_active_record = true
  config.fixture_paths = [ File.join(__dir__, "fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
end

# Ensure FactoryBot loads engine factories (engine root/spec/factories)
FactoryBot.factories.clear
FactoryBot.definition_file_paths = [ File.join(__dir__, "factories") ]
FactoryBot.find_definitions
