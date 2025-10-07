# frozen_string_literal: true

Devise.setup do |config|
  # The secret key used by Devise will be taken from Rails credentials
  # config.secret_key = Rails.application.credentials.secret_key_base

  # ==> Mailer Configuration
  config.mailer_sender = "noreply@nvoi.io"

  # ==> ORM configuration
  require "devise/orm/active_record"

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user
  config.authentication_keys = [:email]

  # ==> OAuth configuration
  # GitHub OAuth will be configured with credentials from the host app
  # The engine will receive credentials via configuration

  # Configure sign out to use GET request (required for some OAuth providers)
  config.sign_out_via = :get

  # ==> Scopes configuration
  config.scoped_views = true

  # ==> Navigation configuration
  config.navigational_formats = ['*/*', :html, :turbo_stream]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = %i[delete get]

  # ==> Mountable engine configuration
  # Set parent controller for the engine
  config.parent_controller = 'Sqema::ApplicationController'

  # ==> OmniAuth
  # OmniAuth providers are configured dynamically via Sqema.configuration
  # in the engine initializer (lib/sqema/engine.rb)

  # Configure OmniAuth to work with the engine's mounted path
  # config.omniauth_path_prefix = '/sqema/users/auth'
end