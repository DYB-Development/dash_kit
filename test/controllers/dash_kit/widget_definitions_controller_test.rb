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
    DashKit.current_owner_method = nil
    if DashKit::ApplicationController.method_defined?(:current_owner)
      DashKit::ApplicationController.send(:remove_method, :current_owner)
    end
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

  test "renders a safe fallback for an unregistered visualization" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "unknown_viz")

    get dash_kit.widget_definition_path(definition)

    assert_response :success
  end

  test "does not expose a definition owned by another owner" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "single_value")
    DashKit.current_owner_method = :current_owner
    DashKit::ApplicationController.class_eval { define_method(:current_owner) { Account.create!(name: "Intruder") } }

    get dash_kit.widget_definition_path(definition)

    assert_response :not_found
  end
end
