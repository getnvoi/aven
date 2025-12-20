# frozen_string_literal: true

module Aven
  class MagicLinkMailer < ApplicationMailer
    # Send sign-in instructions with magic link code
    #
    # @param magic_link [Aven::MagicLink] the magic link record
    def sign_in_instructions(magic_link)
      @magic_link = magic_link
      @user = magic_link.user
      @code = magic_link.code
      @expires_in_minutes = (magic_link.time_remaining / 60).to_i

      mail(
        to: @user.email,
        subject: "Your sign-in code: #{@code}"
      )
    end
  end
end
