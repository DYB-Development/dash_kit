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

  test "index links to the new dashboard form" do
    get dash_kit.dashboards_path

    assert_includes response.body, dash_kit.new_dashboard_path
  end

  test "index marks the active dashboard" do
    DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account, active: true)

    get dash_kit.dashboards_path

    assert_includes response.body, "Active"
  end

  test "index offers a select action for an inactive dashboard" do
    inactive = DashKit::Dashboard.create!(name: "Fulfillment", dashboard_type: "stats", owner: @account)

    get dash_kit.dashboards_path

    assert_includes response.body, dash_kit.select_dashboard_path(inactive)
  end

  test "index links to the rename form for a dashboard" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    get dash_kit.dashboards_path

    assert_includes response.body, dash_kit.edit_dashboard_path(dashboard)
  end

  test "index offers a duplicate action for a dashboard" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    get dash_kit.dashboards_path

    assert_includes response.body, dash_kit.duplicate_dashboard_path(dashboard)
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

  test "select activates the chosen dashboard" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    post dash_kit.select_dashboard_path(dashboard)

    assert dashboard.reload.active?
  end

  test "select redirects to the dashboards index" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    post dash_kit.select_dashboard_path(dashboard)

    assert_redirected_to dash_kit.dashboards_path
  end

  test "select does not activate another owner's dashboard" do
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other_owner)

    post dash_kit.select_dashboard_path(theirs)

    assert_not theirs.reload.active?
  end

  test "edit renders the dashboard's current name" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    get dash_kit.edit_dashboard_path(dashboard)

    assert_includes response.body, "value=\"Sales\""
  end

  test "update renames the dashboard" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    patch dash_kit.dashboard_path(dashboard), params: { dashboard: { name: "Revenue" } }

    assert_equal "Revenue", dashboard.reload.name
  end

  test "update redirects to the dashboards index" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    patch dash_kit.dashboard_path(dashboard), params: { dashboard: { name: "Revenue" } }

    assert_redirected_to dash_kit.dashboards_path
  end

  test "update re-renders the form when invalid" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    patch dash_kit.dashboard_path(dashboard), params: { dashboard: { name: "" } }

    assert_response :unprocessable_entity
  end

  test "update does not rename another owner's dashboard" do
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other_owner)

    patch dash_kit.dashboard_path(theirs), params: { dashboard: { name: "Hijacked" } }

    assert_equal "Theirs", theirs.reload.name
  end

  test "duplicate creates a copy of the dashboard" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert_difference -> { DashKit::Dashboard.count }, 1 do
      post dash_kit.duplicate_dashboard_path(dashboard)
    end
  end

  test "duplicate redirects to the dashboards index" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    post dash_kit.duplicate_dashboard_path(dashboard)

    assert_redirected_to dash_kit.dashboards_path
  end

  test "duplicate does not copy another owner's dashboard" do
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other_owner)

    assert_no_difference -> { DashKit::Dashboard.count } do
      post dash_kit.duplicate_dashboard_path(theirs)
    end
  end

  test "destroy removes the dashboard" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert_difference -> { DashKit::Dashboard.count }, -1 do
      delete dash_kit.dashboard_path(dashboard)
    end
  end

  test "destroy redirects to the dashboards index" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    delete dash_kit.dashboard_path(dashboard)

    assert_redirected_to dash_kit.dashboards_path
  end

  test "destroy does not delete another owner's dashboard" do
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other_owner)

    assert_no_difference -> { DashKit::Dashboard.count } do
      delete dash_kit.dashboard_path(theirs)
    end
  end
end
