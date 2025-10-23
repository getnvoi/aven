# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "webmock/minitest"

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Silence OmniAuth debug output
OmniAuth.config.logger = Logger.new("/dev/null")

# Load test models
require_relative "dummy/app/models/test_project"
require_relative "dummy/app/models/test_resource" if File.exist?(File.join(__dir__, "dummy/app/models/test_resource.rb"))

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Reset WebMock stubs between tests
class ActiveSupport::TestCase
  teardown do
    WebMock.reset!
  end
end
