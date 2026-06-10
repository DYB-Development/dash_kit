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

  test "activate! marks the dashboard active" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    dashboard.activate!

    assert dashboard.active?
  end

  test "activate! deactivates the owner's other dashboards" do
    current = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account, active: true)
    other = DashKit::Dashboard.create!(name: "Fulfillment", dashboard_type: "stats", owner: @account)

    other.activate!

    assert_not current.reload.active?
  end

  test "activate! leaves another owner's active dashboard untouched" do
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other_owner, active: true)
    mine = DashKit::Dashboard.create!(name: "Mine", dashboard_type: "stats", owner: @account)

    mine.activate!

    assert theirs.reload.active?
  end

  test "duplicate! creates a persisted copy" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert dashboard.duplicate!.persisted?
  end

  test "duplicate! assigns the copy to the same owner" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert_equal @account, dashboard.duplicate!.owner
  end

  test "duplicate! copies the source's widget order" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account, widget_order: %w[revenue leads])

    assert_equal %w[revenue leads], dashboard.duplicate!.widget_order
  end

  test "duplicate! names the copy after the source" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert_equal "Sales (copy)", dashboard.duplicate!.name
  end
end
