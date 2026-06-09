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

  test "defaults visibility to private" do
    dashboard = DashKit::Dashboard.new

    assert_equal "private", dashboard.visibility
  end

  test "rejects an unknown visibility" do
    dashboard = DashKit::Dashboard.new(name: "Sales", dashboard_type: "stats", owner: @account, visibility: "world")

    dashboard.valid?

    assert_includes dashboard.errors[:visibility], "is not included in the list"
  end

  test "for_account returns only that account's dashboards" do
    other = Account.create!(name: "Other")
    mine = DashKit::Dashboard.create!(name: "Mine", dashboard_type: "stats", owner: @account, account: @account)
    DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other, account: other)

    assert_equal [ mine ], DashKit::Dashboard.for_account(@account).to_a
  end

  test "for_owner returns only that owner's dashboards" do
    other = Account.create!(name: "Other")
    mine = DashKit::Dashboard.create!(name: "Mine", dashboard_type: "stats", owner: @account)
    DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other)

    assert_equal [ mine ], DashKit::Dashboard.for_owner(@account).to_a
  end
end
