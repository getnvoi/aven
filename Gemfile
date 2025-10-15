source "https://rubygems.org"

# Specify your gem's dependencies in aven.gemspec.
gemspec

gem "puma"
gem "pg", "~> 1.1"
gem "propshaft"
gem "net-ssh", "~> 7.0"

gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# OAuth dependencies (these are in gemspec but needed for development)
gem "omniauth-github", "~> 2.0"
gem "omniauth-google-oauth2", "~> 1.2"

group :development do
  gem "annotaterb", "~> 4.19"
end

# Testing dependencies
group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.5.1"
  gem "shoulda-matchers", "~> 5.3"
  gem "ffaker"
  gem "database_cleaner", "~> 2.1.0"
  gem "webmock", "~> 3.24"
end

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem("aeros", github: "getnvoi/ui", branch: :main)
