module Aven
  class Configuration
    attr_accessor :authenticated_root_path
    attr_accessor :oauth_providers

    def initialize
      @authenticated_root_path = nil
      @oauth_providers = {}
    end

    # Configure OAuth providers
    #
    # @param provider [Symbol] The OAuth provider name (:github, :google, etc.)
    # @param credentials [Hash] Configuration hash with:
    #   - :client_id [String] OAuth client ID
    #   - :client_secret [String] OAuth client secret
    #   - :scope [String] Optional. OAuth scopes to request
    #   - Any other provider-specific options
    #
    # @example
    #   config.configure_oauth(:github, {
    #     client_id: "abc123",
    #     client_secret: "secret",
    #     scope: "user:email,repo,workflow"
    #   })
    def configure_oauth(provider, credentials = {})
      @oauth_providers[provider.to_sym] = credentials
    end

    # Resolves authenticated_root_path, calling it if it's a lambda/proc
    #
    # @return [String] The resolved path
    def resolve_authenticated_root_path
      return nil if @authenticated_root_path.nil?

      @authenticated_root_path.respond_to?(:call) ? @authenticated_root_path.call : @authenticated_root_path
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
