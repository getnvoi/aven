# frozen_string_literal: true

require "test_helper"

class Aven::MagicLinkMailerTest < ActionMailer::TestCase
  def setup
    @user = Aven::User.create!(
      email: "mailer-test@example.com",
      auth_tenant: "www.example.com"
    )
    @magic_link = @user.magic_links.create!(purpose: :sign_in)
  end

  test "sign_in_instructions sends to correct recipient" do
    email = Aven::MagicLinkMailer.sign_in_instructions(@magic_link)

    assert_equal [@user.email], email.to
  end

  test "sign_in_instructions includes code in subject" do
    email = Aven::MagicLinkMailer.sign_in_instructions(@magic_link)

    assert_includes email.subject, @magic_link.code
  end

  test "sign_in_instructions subject format" do
    email = Aven::MagicLinkMailer.sign_in_instructions(@magic_link)

    assert_equal "Your sign-in code: #{@magic_link.code}", email.subject
  end

  test "sign_in_instructions includes code in body" do
    email = Aven::MagicLinkMailer.sign_in_instructions(@magic_link)

    assert_includes email.text_part.body.to_s, @magic_link.code
    assert_includes email.html_part.body.to_s, @magic_link.code
  end

  test "sign_in_instructions includes expiry information" do
    email = Aven::MagicLinkMailer.sign_in_instructions(@magic_link)

    # Should mention minutes
    assert_match(/\d+ minutes?/, email.text_part.body.to_s)
    assert_match(/\d+ minutes?/, email.html_part.body.to_s)
  end

  test "sign_in_instructions is deliverable" do
    assert_emails 1 do
      Aven::MagicLinkMailer.sign_in_instructions(@magic_link).deliver_now
    end
  end

  test "sign_in_instructions generates multipart email" do
    email = Aven::MagicLinkMailer.sign_in_instructions(@magic_link)

    assert email.multipart?
    assert email.text_part.present?
    assert email.html_part.present?
  end
end
