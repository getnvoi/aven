# config/initializers/aven.rb
Aven.configure do |config|
  config.auth.add(
    :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
    scope: 'email,profile',
    path_prefix: "/aven/users/auth"
  )
end
