# frozen_string_literal: true

require "test_helper"

class DashKit::AuthorizationTest < ActiveSupport::TestCase
  FakeDashboard = Struct.new(:owner)

  teardown do
    DashKit.viewable_by = DashKit::OWNER_EQUALITY
    DashKit.editable_by = DashKit::OWNER_EQUALITY
    DashKit.shareable_by = DashKit::OWNER_EQUALITY
  end

  test "viewable? is true for the dashboard owner by default" do
    dashboard = FakeDashboard.new("owner-1")

    assert DashKit.viewable?(dashboard, "owner-1")
  end

  test "viewable? is false for a non-owner by default" do
    dashboard = FakeDashboard.new("owner-1")

    refute DashKit.viewable?(dashboard, "someone-else")
  end

  test "editable? uses the host-configured predicate" do
    DashKit.editable_by = ->(_dashboard, viewer) { viewer == "editor" }
    dashboard = FakeDashboard.new("owner-1")

    assert DashKit.editable?(dashboard, "editor")
  end

  test "shareable? uses the host-configured predicate" do
    DashKit.shareable_by = ->(_dashboard, viewer) { viewer == "sharer" }
    dashboard = FakeDashboard.new("owner-1")

    assert DashKit.shareable?(dashboard, "sharer")
  end
end
