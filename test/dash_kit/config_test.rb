# frozen_string_literal: true

require "test_helper"

class DashKit::ConfigTest < ActiveSupport::TestCase
  test "parent_controller defaults to DashKit::ApplicationController" do
    assert_equal "DashKit::ApplicationController", DashKit.parent_controller
  end

  test "current_owner_method defaults to nil" do
    assert_nil DashKit.current_owner_method
  end
end
