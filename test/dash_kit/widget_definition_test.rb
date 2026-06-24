# frozen_string_literal: true

require "test_helper"

class DashKit::WidgetDefinitionTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
    @dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)
  end

  test "a dashboard has many widget definitions" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "single_value")

    assert_includes @dashboard.widget_definitions, definition
  end

  test "stores the source verbatim" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "single_value")

    assert_equal "revenue", definition.reload.source
  end

  test "stores the visualization verbatim" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "single_value")

    assert_equal "single_value", definition.reload.visualization
  end

  test "stores the options hash verbatim" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "chart", options: { "color" => "blue" })

    assert_equal({ "color" => "blue" }, definition.reload.options)
  end
end
