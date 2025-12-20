# frozen_string_literal: true

require "test_helper"

module Aven
  module System
    class SessionsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @system_user = aven_system_users(:one)
      end

      test "should get new" do
        get aven.system_login_path
        assert_response :success
      end

      test "should create session with valid credentials" do
        post aven.system_login_path, params: { email: @system_user.email, password: "password123456" }
        assert_redirected_to aven.system_root_path
        assert session[:system_user_id].present?
      end

      test "should not create session with invalid credentials" do
        post aven.system_login_path, params: { email: @system_user.email, password: "wrongpassword" }
        assert_response :unprocessable_entity
        assert_nil session[:system_user_id]
      end

      test "should destroy session" do
        post aven.system_login_path, params: { email: @system_user.email, password: "password123456" }
        delete aven.system_logout_path
        assert_redirected_to aven.system_login_path
        assert_nil session[:system_user_id]
      end
    end
  end
end
