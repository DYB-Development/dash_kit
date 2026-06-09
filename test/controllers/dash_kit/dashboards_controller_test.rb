# frozen_string_literal: true

require "test_helper"

class DashKit::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(name: "Test")
  end

  test "index lists a dashboard by name" do
    DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    get dash_kit.dashboards_path

    assert_includes response.body, "Sales"
  end
end
