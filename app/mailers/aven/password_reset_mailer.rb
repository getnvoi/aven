# frozen_string_literal: true

module Aven
  class PasswordResetMailer < ApplicationMailer
    # Send password reset instructions
    #
    # @param user [Aven::User] the user requesting reset
    # @param token [String] the password reset token
    def reset_instructions(user, token)
      @user = user
      @token = token
      @reset_url = auth_edit_password_reset_url(token: token)
      @expires_in_minutes = (Aven.configuration.password_reset_expiry / 60).to_i

      mail(
        to: @user.email,
        subject: "Reset your password"
      )
    end
  end
end
