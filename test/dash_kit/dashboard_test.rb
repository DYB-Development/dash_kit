# frozen_string_literal: true

require "test_helper"

class DashKit::DashboardTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
  end

  test "requires a name" do
    dashboard = DashKit::Dashboard.new(dashboard_type: "home", owner: @account)

    dashboard.valid?

    assert_includes dashboard.errors[:name], "can't be blank"
  end

  test "requires a dashboard_type" do
    dashboard = DashKit::Dashboard.new(name: "Sales", owner: @account)

    dashboard.valid?

    assert_includes dashboard.errors[:dashboard_type], "can't be blank"
  end

  test "allows multiple dashboards per owner and type" do
    DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    second = DashKit::Dashboard.new(name: "Fulfillment", dashboard_type: "stats", owner: @account)

    assert second.valid?
  end
end
