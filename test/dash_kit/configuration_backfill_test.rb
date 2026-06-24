# frozen_string_literal: true

require "test_helper"

class DashKit::ConfigurationBackfillTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
  end

  test "creates a Dashboard for each Configuration" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home")

    DashKit::ConfigurationBackfill.run

    assert DashKit::Dashboard.for_owner(@account).exists?(dashboard_type: "home")
  end

  test "carries over the widget_order" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home", widget_order: %w[tasks on_deck])

    DashKit::ConfigurationBackfill.run

    assert_equal %w[tasks on_deck], DashKit::Dashboard.for_owner(@account).last.widget_order
  end

  test "carries over hidden_widgets" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home", hidden_widgets: %w[goals])

    DashKit::ConfigurationBackfill.run

    assert_equal %w[goals], DashKit::Dashboard.for_owner(@account).last.hidden_widgets
  end

  test "carries over filter_state" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home", filter_state: { "preset" => "last_7_days" })

    DashKit::ConfigurationBackfill.run

    assert_equal({ "preset" => "last_7_days" }, DashKit::Dashboard.for_owner(@account).last.filter_state)
  end

  test "carries over widget_settings" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home", widget_settings: { "tasks" => { "limit" => 5 } })

    DashKit::ConfigurationBackfill.run

    assert_equal({ "tasks" => { "limit" => 5 } }, DashKit::Dashboard.for_owner(@account).last.widget_settings)
  end

  test "is idempotent across re-runs" do
    DashKit::Configuration.create!(owner: @account, dashboard_type: "home")

    DashKit::ConfigurationBackfill.run
    DashKit::ConfigurationBackfill.run

    assert_equal 1, DashKit::Dashboard.for_owner(@account).count
  end
end
