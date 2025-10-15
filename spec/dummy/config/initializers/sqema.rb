# config/initializers/aven.rb
Aven.configure do |config|
  # Configure Google OAuth (optional, for testing)
  if ENV['GOOGLE_CLIENT_ID'].present? && ENV['GOOGLE_CLIENT_SECRET'].present?
    config.configure_oauth(:google, {
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: 'openid email profile'
    })
  end
end
