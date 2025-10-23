module Aven
  class AuthController < ApplicationController
    def logout
      sign_out
      begin
        redirect_to(main_app.root_path, notice: "You have been signed out successfully.")
      rescue NoMethodError
        redirect_to(root_path, notice: "You have been signed out successfully.")
      end
    end
  end
end
