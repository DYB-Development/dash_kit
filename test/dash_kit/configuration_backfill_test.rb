# frozen_string_literal: true

require "test_helper"

class DashKit::ConfigurationBackfillTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
  end

  def legacy_config(**attrs)
    DashKit::ConfigurationBackfill::LegacyConfiguration.create!(
      owner_type: @account.class.name, owner_id: @account.id, dashboard_type: "home", **attrs
    )
  end

  test "creates a Dashboard for each Configuration" do
    legacy_config

    DashKit::ConfigurationBackfill.run

    assert DashKit::Dashboard.for_owner(@account).exists?(dashboard_type: "home")
  end

  test "carries over the widget_order" do
    legacy_config(widget_order: %w[tasks on_deck])

    DashKit::ConfigurationBackfill.run

    assert_equal %w[tasks on_deck], DashKit::Dashboard.for_owner(@account).last.widget_order
  end

  test "carries over hidden_widgets" do
    legacy_config(hidden_widgets: %w[goals])

    DashKit::ConfigurationBackfill.run

    assert_equal %w[goals], DashKit::Dashboard.for_owner(@account).last.hidden_widgets
  end

  test "carries over filter_state" do
    legacy_config(filter_state: { "preset" => "last_7_days" })

    DashKit::ConfigurationBackfill.run

    assert_equal({ "preset" => "last_7_days" }, DashKit::Dashboard.for_owner(@account).last.filter_state)
  end

  test "carries over widget_settings" do
    legacy_config(widget_settings: { "tasks" => { "limit" => 5 } })

    DashKit::ConfigurationBackfill.run

    assert_equal({ "tasks" => { "limit" => 5 } }, DashKit::Dashboard.for_owner(@account).last.widget_settings)
  end

  test "is idempotent across re-runs" do
    legacy_config

    DashKit::ConfigurationBackfill.run
    DashKit::ConfigurationBackfill.run

    assert_equal 1, DashKit::Dashboard.for_owner(@account).count
  end

  test "is a no-op when the legacy table is absent" do
    DashKit::ConfigurationBackfill::LegacyConfiguration.table_name = "dash_kit_absent_configs"

    assert_nothing_raised { DashKit::ConfigurationBackfill.run }
  ensure
    DashKit::ConfigurationBackfill::LegacyConfiguration.table_name = "dash_kit_configurations"
  end
end
