# config/initializers/sqema.rb
Sqema.configure do |config|
  config.auth.add(
    :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
    scope: 'email,profile',
    path_prefix: "/sqema/users/auth"
  )
end
