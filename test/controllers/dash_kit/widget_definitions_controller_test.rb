# frozen_string_literal: true

require "test_helper"

class DashKit::WidgetDefinitionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DashKit.reset_renderers!
    DashKit.register_renderer(:single_value, partial: "renderers/single_value")
    @dashboard = DashKit::Dashboard.create!(
      name: "Home", owner: Account.create!(name: "Acme"), dashboard_type: "home",
      filter_state: { "preset" => "last_7_days" }
    )
  end

  teardown do
    DashKit.reset_renderers!
  end

  test "renders a definition through its host renderer with source, options and filter_state" do
    definition = @dashboard.widget_definitions.create!(
      source: "revenue", visualization: "single_value", options: { "unit" => "usd" }
    )

    get dash_kit.widget_definition_path(definition)

    assert_response :success
    assert_match "source=revenue", response.body
    assert_match "usd", response.body
    assert_match "last_7_days", response.body
  end
end
