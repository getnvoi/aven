module Aven
  class Configuration
    attr_accessor :authenticated_root_path
    attr_accessor :oauth_providers
    attr_accessor :agentic
    attr_accessor :ocr
    attr_accessor :schemas

    # Authentication options
    attr_accessor :enable_magic_link
    attr_accessor :magic_link_expiry
    attr_accessor :enable_password_auth
    attr_accessor :enable_password_registration
    attr_accessor :password_minimum_length
    attr_accessor :password_reset_expiry
    attr_accessor :session_expiry

    # Mailer configuration
    attr_accessor :mailer_from_address

    # Lifecycle callbacks
    attr_accessor :after_migrate_callback

    def initialize
      @authenticated_root_path = nil
      @oauth_providers = {}
      @agentic = AgenticConfiguration.new
      @ocr = OcrConfiguration.new
      @schemas = []

      # Auth defaults
      @enable_magic_link = true
      @magic_link_expiry = 15.minutes
      @enable_password_auth = false
      @enable_password_registration = false
      @password_minimum_length = 12
      @password_reset_expiry = 20.minutes
      @session_expiry = 30.days

      # Mailer defaults
      @mailer_from_address = nil

      # Lifecycle callbacks
      @after_migrate_callback = nil
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

    # Check if an OAuth provider is configured
    #
    # @param provider [Symbol] The OAuth provider name
    # @return [Boolean] Whether the provider is configured
    def oauth_configured?(provider)
      config = @oauth_providers[provider.to_sym]
      config.present? && config[:client_id].present? && config[:client_secret].present?
    end

    # Check if magic link authentication is enabled
    #
    # @return [Boolean] Whether magic link is enabled
    def magic_link_enabled?
      @enable_magic_link
    end

    # Check if password authentication is enabled
    #
    # @return [Boolean] Whether password auth is enabled
    def password_auth_enabled?
      @enable_password_auth
    end
  end

  # Agentic configuration (LLM, tools, chat)
  class AgenticConfiguration
    attr_accessor :default_model
    attr_accessor :system_prompt
    attr_accessor :tools_enabled
    attr_accessor :mcp_enabled
    attr_accessor :mcp_api_token

    def initialize
      @default_model = "claude-sonnet-4-5-20250929"
      @system_prompt = "You are a helpful assistant."
      @tools_enabled = true
      @mcp_enabled = false
      @mcp_api_token = nil
    end
  end

  # OCR configuration
  class OcrConfiguration
    attr_accessor :provider
    attr_accessor :aws_region
    attr_accessor :aws_access_key_id
    attr_accessor :aws_secret_access_key

    def initialize
      @provider = nil  # :textract, :google_vision, etc.
      @aws_region = nil
      @aws_access_key_id = nil
      @aws_secret_access_key = nil
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
