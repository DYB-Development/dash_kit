# frozen_string_literal: true

require "test_helper"

class DashKit::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(name: "Test")
    DashKit.current_owner_method = :current_owner
    DashKit::ApplicationController.class_eval do
      def current_owner
        Account.first
      end
    end
  end

  teardown do
    DashKit.current_owner_method = nil
    DashKit::ApplicationController.send(:remove_method, :current_owner)
  end

  test "index lists a dashboard by name" do
    DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    get dash_kit.dashboards_path

    assert_includes response.body, "Sales"
  end

  test "index shows an empty state when there are no dashboards" do
    get dash_kit.dashboards_path

    assert_includes response.body, "No dashboards yet."
  end

  test "new renders a name field" do
    get dash_kit.new_dashboard_path

    assert_includes response.body, "dashboard[name]"
  end

  test "create persists a new dashboard" do
    assert_difference -> { DashKit::Dashboard.count }, 1 do
      post dash_kit.dashboards_path, params: { dashboard: { name: "Sales", dashboard_type: "stats" } }
    end
  end

  test "create assigns the dashboard to the current owner" do
    post dash_kit.dashboards_path, params: { dashboard: { name: "Sales", dashboard_type: "stats" } }

    assert_equal @account, DashKit::Dashboard.last.owner
  end

  test "create redirects to the dashboards index" do
    post dash_kit.dashboards_path, params: { dashboard: { name: "Sales", dashboard_type: "stats" } }

    assert_redirected_to dash_kit.dashboards_path
  end

  test "create re-renders the form when invalid" do
    post dash_kit.dashboards_path, params: { dashboard: { name: "", dashboard_type: "stats" } }

    assert_response :unprocessable_entity
  end
end
