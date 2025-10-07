source "https://rubygems.org"

# Specify your gem's dependencies in sqema.gemspec.
gemspec

gem "puma"
gem "pg", "~> 1.1"
gem "propshaft"
gem "net-ssh", "~> 7.0"

gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# OAuth dependencies (these are in gemspec but needed for development)
gem "devise", "~> 4.9"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0.0"
gem "omniauth-github", "~> 2.0"
gem "repost", "~> 0.4.2"

# Testing dependencies
group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4.4"
  gem "shoulda-matchers", "~> 5.3"
  gem "ffaker"
  gem "database_cleaner", "~> 2.0.1"
end

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
