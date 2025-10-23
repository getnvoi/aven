require_relative "lib/aven/version"

Gem::Specification.new do |spec|
  spec.name        = "aven"
  spec.version     = Aven::VERSION
  spec.authors     = [ "Ben" ]
  spec.email       = [ "ben@dee.mx" ]
  spec.homepage    = "https://github.com/getnvoi/aven"
  spec.summary     = "Authentication engine for Rails applications."
  spec.description = "A Rails engine providing authentication with OAuth support (GitHub, Google, Auth0)."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/getnvoi/aven"
  spec.metadata["changelog_uri"] = "https://github.com/getnvoi/aven/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.3"
  spec.add_dependency "importmap-rails", "~> 2.2.2"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "tailwindcss-rails", "~> 4.3.0"
  spec.add_dependency "view_component", "~> 4.0"
  spec.add_dependency "view_component-contrib", "~> 0.2.5"
  spec.add_dependency "dry-effects", "~> 0.5.0"
  spec.add_dependency "tailwind_merge", "~> 1.3"
  spec.add_dependency "random_username", "~> 1.1"
  spec.add_dependency "dotenv-rails", "~> 3.1"
  spec.add_dependency "json_skooma"
  spec.add_dependency "friendly_id", "~> 5.5"
end
