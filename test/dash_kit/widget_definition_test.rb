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
end
