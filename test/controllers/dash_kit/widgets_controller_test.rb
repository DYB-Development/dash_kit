# frozen_string_literal: true

require "test_helper"

class DashKit::WidgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      end
    end
  end

  test "show renders widget partial" do
    get dash_kit.widget_path(:on_deck)
    assert_response :success
    assert_match "On Deck Widget", response.body
  end

  test "show returns 404 for unknown widget" do
    get dash_kit.widget_path(:nonexistent)
    assert_response :not_found
  end

  test "show passes the dashboard's filter_state to the widget partial" do
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :filtered, label: "Filtered", partial: "widgets/home/filtered"
      end
    end
    dashboard = DashKit::Dashboard.create!(
      name: "Home", owner: Account.create!(name: "Acme"), dashboard_type: "home",
      widget_order: %w[filtered], hidden_widgets: [],
      filter_state: { "mode" => "rolling", "preset" => "last_7_days" }
    )

    get dash_kit.widget_path(:filtered, dashboard_id: dashboard.id)

    assert_match "last_7_days", response.body
  end
end
