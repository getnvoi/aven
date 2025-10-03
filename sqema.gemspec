require_relative "lib/sqema/version"

Gem::Specification.new do |spec|
  spec.name        = "sqema"
  spec.version     = Sqema::VERSION
  spec.authors     = [ "Ben" ]
  spec.email       = [ "ben@dee.mx" ]
  spec.homepage    = "TODO"
  spec.summary     = "TODO: Summary of Sqema."
  spec.description = "TODO: Description of Sqema."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.3"
  spec.add_dependency "devise", "~> 4.9"
  spec.add_dependency "omniauth", "~> 2.1"
  spec.add_dependency "omniauth-rails_csrf_protection", "~> 1.0.0"
  spec.add_dependency "omniauth-github", "~> 2.0"
  spec.add_dependency "repost", "~> 0.4.2"
  spec.add_dependency "importmap-rails", "~> 2.2.2"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "tailwindcss-rails", "~> 4.3.0"
  spec.add_dependency "view_component", "~> 4.0"
  spec.add_dependency "view_component-contrib", "~> 0.2.5"
  spec.add_dependency "dry-effects", "~> 0.5.0"
  spec.add_dependency "tailwind_merge", "~> 1.3"
  spec.add_dependency "random_username", "~> 1.1"
  spec.add_dependency "omniauth-google-oauth2", "~> 1.2"
  spec.add_dependency "dotenv-rails", "~> 3.1"

  spec.add_development_dependency "rspec-rails", "~> 6.1"
  spec.add_development_dependency "factory_bot_rails", "~> 6.4.4"
  spec.add_development_dependency "shoulda-matchers", "~> 5.3"
  spec.add_development_dependency "ffaker"
end
