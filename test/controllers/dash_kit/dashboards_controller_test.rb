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
    DashKit.current_viewer_method = nil
    DashKit.editable_by = DashKit::OWNER_EQUALITY
    DashKit::ApplicationController.send(:remove_method, :current_owner)
  end

  def register_home_widgets
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
        d.widget :tasks, label: "Tasks", partial: "widgets/home/tasks"
        d.widget :goals, label: "Goals", partial: "widgets/home/goals"
      end
    end
  end

  def home_dashboard
    DashKit::Dashboard.create!(
      name: "Home", owner: @account, dashboard_type: "home",
      widget_order: %w[on_deck tasks goals], hidden_widgets: []
    )
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

  test "index offers a delete action for a dashboard" do
    DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    get dash_kit.dashboards_path

    assert_includes response.body, "value=\"delete\""
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

  test "toggle_widget hides a visible widget" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.toggle_widget_dashboard_path(dashboard), params: { widget_key: "tasks" }

    assert_includes dashboard.reload.hidden_widgets, "tasks"
  end

  test "toggle_widget turbo_stream replaces the settings modal" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.toggle_widget_dashboard_path(dashboard), params: { widget_key: "tasks" }, as: :turbo_stream

    assert_includes response.body, "dashboard-settings-modal"
  end

  test "settings modal uses the keystone modal backdrop target" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.toggle_widget_dashboard_path(dashboard), params: { widget_key: "tasks" }, as: :turbo_stream

    assert_includes response.body, %(data-modal-target="backdrop")
  end

  test "move_widget up swaps with the previous widget" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.move_widget_dashboard_path(dashboard), params: { widget_key: "tasks", direction: "up" }

    assert_equal %w[tasks on_deck goals], dashboard.reload.widget_order
  end

  test "reorder updates the widget order with valid keys" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.reorder_dashboard_path(dashboard), params: { widget_order: %w[goals tasks on_deck] }

    assert_equal %w[goals tasks on_deck], dashboard.reload.widget_order
  end

  test "reorder rejects invalid keys" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.reorder_dashboard_path(dashboard), params: { widget_order: %w[goals fake_widget] }

    assert_response :unprocessable_entity
  end

  test "save_filters updates the filter state" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.save_filters_dashboard_path(dashboard), params: { filter_key: "time_period", filter_value: "last_7_days" }

    assert_equal "last_7_days", dashboard.reload.filter_state["time_period"]
  end

  test "save_filters re-renders the widgets via turbo stream" do
    register_home_widgets
    dashboard = home_dashboard

    post dash_kit.save_filters_dashboard_path(dashboard),
      params: { filter_key: "time_period", filter_value: "last_7_days" }, as: :turbo_stream

    assert_match(/<turbo-stream action="replace" target="dashboard-widgets">/, response.body)
  end

  test "a saved filter is visible when a widget reloads" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :filtered, label: "Filtered", partial: "widgets/home/filtered"
      end
    end
    dashboard = DashKit::Dashboard.create!(
      name: "Home", owner: @account, dashboard_type: "home",
      widget_order: %w[filtered], hidden_widgets: []
    )

    post dash_kit.save_filters_dashboard_path(dashboard), params: { filter_key: "time_period", filter_value: "last_7_days" }
    get dash_kit.widget_path(:filtered, dashboard_id: dashboard.id)

    assert_match "last_7_days", response.body
  end

  test "reorder is forbidden when the viewer cannot edit" do
    register_home_widgets
    dashboard = home_dashboard
    DashKit.editable_by = ->(_dashboard, _viewer) { false }

    post dash_kit.reorder_dashboard_path(dashboard), params: { widget_order: %w[goals tasks on_deck] }

    assert_response :forbidden
  end

  test "writes are not enforced when no viewer is configured" do
    register_home_widgets
    dashboard = home_dashboard
    DashKit.current_owner_method = nil
    DashKit.editable_by = ->(_dashboard, _viewer) { false }

    post dash_kit.reorder_dashboard_path(dashboard), params: { widget_order: %w[goals tasks on_deck] }

    assert_equal %w[goals tasks on_deck], dashboard.reload.widget_order
  end

  test "editable? receives the configured viewer rather than the owner" do
    register_home_widgets
    dashboard = home_dashboard
    received = nil
    DashKit.editable_by = ->(_dashboard, viewer) { received = viewer; true }

    begin
      DashKit::ApplicationController.class_eval { def current_member_stub; "member-7"; end }
      DashKit.current_viewer_method = :current_member_stub

      post dash_kit.reorder_dashboard_path(dashboard), params: { widget_order: %w[goals tasks on_deck] }

      assert_equal "member-7", received
    ensure
      DashKit::ApplicationController.send(:remove_method, :current_member_stub)
    end
  end

  test "create_definition persists a definition" do
    register_home_widgets
    dashboard = home_dashboard

    assert_difference -> { DashKit::WidgetDefinition.count }, 1 do
      post dash_kit.create_definition_dashboard_path(dashboard),
        params: { widget_definition: { source: "revenue", visualization: "line_chart" } }
    end
  end

  test "toggle_widget does not affect another owner's dashboard" do
    register_home_widgets
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(
      name: "Theirs", owner: other_owner, dashboard_type: "home",
      widget_order: %w[on_deck tasks goals], hidden_widgets: []
    )

    post dash_kit.toggle_widget_dashboard_path(theirs), params: { widget_key: "tasks" }

    assert_response :not_found
  end
end
