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
  config.authentication_keys = [ :email ]

  # ==> Sign out configuration

  # ==> Scopes configuration
  config.scoped_views = true

  # ==> Navigation configuration
  config.navigational_formats = [ "*/*", :html, :turbo_stream ]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = %i[delete get]

  # ==> Mountable engine configuration
  # Set parent controller for the engine
  config.parent_controller = "Aven::ApplicationController"

  # ==> OmniAuth
  # OmniAuth providers are configured dynamically via Aven.configuration
  # in the engine initializer (lib/aven/engine.rb)

  # Configure OmniAuth to work with the engine's mounted path
  # config.omniauth_path_prefix = '/aven/users/auth'
end
