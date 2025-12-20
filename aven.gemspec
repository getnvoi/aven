require_relative "lib/aven/version"

Gem::Specification.new do |spec|
  spec.name        = "aven"
  spec.version     = Aven::VERSION
  spec.authors     = [ "Ben" ]
  spec.email       = [ "ben@dee.mx" ]
  spec.homepage    = "https://github.com/getnvoi/aven"
  spec.summary     = "Authentication and AI-powered agentic engine for Rails applications."
  spec.description = "A Rails engine providing OAuth authentication, workspace multi-tenancy, and AI agentic capabilities with LLM chat, tools, and MCP support."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/getnvoi/aven"
  spec.metadata["changelog_uri"] = "https://github.com/getnvoi/aven/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  # Rails
  spec.add_dependency "rails", ">= 8.0.3"

  # Frontend
  spec.add_dependency "importmap-rails", "~> 2.2.2"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "view_component", "~> 4.0"
  spec.add_dependency "view_component-contrib", "~> 0.2.5"

  # Utilities
  spec.add_dependency "aeno"
  spec.add_dependency "dry-effects", "~> 0.5.0"
  spec.add_dependency "random_username", "~> 1.1"
  spec.add_dependency "dotenv-rails", "~> 3.1"
  spec.add_dependency "json_skooma"
  spec.add_dependency "friendly_id", "~> 5.5"
  spec.add_dependency "acts-as-taggable-on", ">= 12", "< 14"

  # Search
  spec.add_dependency "pg_search", "~> 2.3"

  # Pagination
  spec.add_dependency "kaminari", "~> 1.2"

  # OAuth
  spec.add_dependency "omniauth-github", "~> 2.0"
  spec.add_dependency "omniauth-google-oauth2", "~> 1.2"

  # Password authentication
  spec.add_dependency "bcrypt", "~> 3.1"

  # Google APIs
  spec.add_dependency "google-apis-people_v1", "~> 0.42"

  # AI / Agentic
  spec.add_dependency "ruby_llm", "~> 1.9"
  spec.add_dependency "mcp", "~> 0.2"
  spec.add_dependency "neighbor", "~> 0.6"
end
