# frozen_string_literal: true

require "test_helper"

class DashKit::ConfigurationTest < ActiveSupport::TestCase
  setup do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
        d.widget :tasks, label: "Tasks", partial: "widgets/home/tasks"
        d.widget :goals, label: "Goals", partial: "widgets/home/goals"
      end
    end

    @account = Account.create!(name: "Test")
  end

  test "ordered_visible_widgets excludes hidden widgets" do
    config = DashKit::Configuration.new(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: %w[tasks]
    )

    assert_equal %w[on_deck goals], config.ordered_visible_widgets
  end

  test "toggle_widget hides a visible widget" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: []
    )

    config.toggle_widget(:tasks)
    assert_includes config.hidden_widgets, "tasks"
  end

  test "toggle_widget shows a hidden widget" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: %w[tasks]
    )

    config.toggle_widget(:tasks)
    refute_includes config.hidden_widgets, "tasks"
  end

  test "move_widget_up swaps with previous widget" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: []
    )

    config.move_widget_up(:tasks)
    assert_equal %w[tasks on_deck goals], config.reload.widget_order
  end

  test "move_widget_up does nothing for first widget" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: []
    )

    config.move_widget_up(:on_deck)
    assert_equal %w[on_deck tasks goals], config.reload.widget_order
  end

  test "move_widget_down swaps with next widget" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: []
    )

    config.move_widget_down(:tasks)
    assert_equal %w[on_deck goals tasks], config.reload.widget_order
  end

  test "move_widget_down does nothing for last widget" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: []
    )

    config.move_widget_down(:goals)
    assert_equal %w[on_deck tasks goals], config.reload.widget_order
  end

  test "update_filter merges into filter_state" do
    config = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck tasks goals],
      hidden_widgets: [],
      filter_state: { "time_period" => "last_30_days" }
    )

    config.update_filter(:time_period, "last_7_days")
    assert_equal "last_7_days", config.reload.filter_state["time_period"]
  end

  test "for_owner finds existing configuration" do
    existing = DashKit::Configuration.create!(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[goals on_deck tasks],
      hidden_widgets: %w[tasks]
    )

    found = DashKit::Configuration.for_owner(@account, :home)
    assert_equal existing, found
    assert_equal %w[goals on_deck tasks], found.widget_order
  end

  test "for_owner initializes new configuration with defaults" do
    config = DashKit::Configuration.for_owner(@account, :home)

    assert config.new_record?
    assert_equal %w[on_deck tasks goals], config.widget_order
    assert_equal [], config.hidden_widgets
  end

  test "available_widgets returns registered widgets for dashboard type" do
    config = DashKit::Configuration.new(dashboard_type: "home")

    widgets = config.available_widgets
    assert_equal %i[on_deck tasks goals], widgets.keys
    assert_equal "On Deck", widgets[:on_deck][:label]
  end

  test "ordered_visible_widgets excludes unregistered widgets" do
    config = DashKit::Configuration.new(
      owner: @account,
      dashboard_type: "home",
      widget_order: %w[on_deck stale_widget tasks goals removed_feature],
      hidden_widgets: []
    )

    assert_equal %w[on_deck tasks goals], config.ordered_visible_widgets
  end

  test "widget_visible? returns true for non-hidden widgets" do
    config = DashKit::Configuration.new(
      dashboard_type: "home",
      hidden_widgets: %w[tasks]
    )

    assert config.widget_visible?(:on_deck)
    refute config.widget_visible?(:tasks)
  end
end
