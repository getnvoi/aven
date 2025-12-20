# frozen_string_literal: true

require "test_helper"

module Aven
  module System
    class ActivitiesControllerTest < ActionDispatch::IntegrationTest
      test "should get index when authenticated" do
        system_user = aven_system_users(:one)
        post aven.system_login_path, params: { email: system_user.email, password: "password123456" }
        get aven.system_activities_path
        assert_response :success
      end

      test "should redirect to login when not authenticated" do
        get aven.system_activities_path
        assert_redirected_to aven.system_login_path
      end
    end
  end
end
