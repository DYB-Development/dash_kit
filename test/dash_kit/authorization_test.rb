# frozen_string_literal: true

require "test_helper"

class DashKit::AuthorizationTest < ActiveSupport::TestCase
  FakeDashboard = Struct.new(:owner)

  test "viewable? is true for the dashboard owner by default" do
    dashboard = FakeDashboard.new("owner-1")

    assert DashKit.viewable?(dashboard, "owner-1")
  end
end
