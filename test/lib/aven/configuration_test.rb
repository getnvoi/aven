# frozen_string_literal: true

require "test_helper"

module Aven
  class ConfigurationTest < ActiveSupport::TestCase
    setup do
      @config = Configuration.new
    end

    test "authenticated_root_path accepts string value" do
      @config.authenticated_root_path = "/dashboard"

      assert_equal("/dashboard", @config.resolve_authenticated_root_path)
    end

    test "authenticated_root_path accepts lambda and calls it" do
      @config.authenticated_root_path = -> { "/dynamic/path" }

      assert_equal("/dynamic/path", @config.resolve_authenticated_root_path)
    end

    test "authenticated_root_path accepts proc and calls it" do
      @config.authenticated_root_path = proc { "/proc/path" }

      assert_equal("/proc/path", @config.resolve_authenticated_root_path)
    end

    test "resolve_authenticated_root_path returns nil when not configured" do
      assert_nil(@config.resolve_authenticated_root_path)
    end

    test "lambda can be used with dynamic values" do
      # Example of a lambda that could use context-aware logic
      dynamic_path = "/admin"
      @config.authenticated_root_path = -> { dynamic_path }

      assert_equal("/admin", @config.resolve_authenticated_root_path)
    end

    test "lambda can accept parameters if needed" do
      counter = 0
      @config.authenticated_root_path = -> { counter += 1; "/path/#{counter}" }

      assert_equal("/path/1", @config.resolve_authenticated_root_path)
      assert_equal("/path/2", @config.resolve_authenticated_root_path)
    end

    test "configure_oauth sets provider credentials" do
      @config.configure_oauth(:github, { client_id: "abc123", client_secret: "secret" })

      assert_equal("abc123", @config.oauth_providers[:github][:client_id])
      assert_equal("secret", @config.oauth_providers[:github][:client_secret])
    end
  end
end
