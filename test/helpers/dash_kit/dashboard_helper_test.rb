# frozen_string_literal: true

require "test_helper"

module DashKit
  class DashboardHelperTest < ActionView::TestCase
    include DashKit::DashboardHelper
    include KeystoneUiHelper
    include DashKit::Engine.routes.url_helpers

    setup do
      DashKit.reset_registry!
      DashKit.configure do |r|
        r.register(:test_dashboard) do |d|
          d.widget :stats, label: "Stats", partial: "widgets/stats"
          d.widget :chart, label: "Chart", partial: "widgets/chart"
        end
      end

      @config = DashKit::Dashboard.create!(
        name: "Test", dashboard_type: "test_dashboard", owner: Account.create!(name: "Test"),
        widget_order: %w[stats chart], hidden_widgets: []
      )
    end

    teardown do
      DashKit.current_viewer_method = nil
      DashKit.viewable_by = DashKit::OWNER_EQUALITY
      DashKit.editable_by = DashKit::OWNER_EQUALITY
      DashKit.shareable_by = DashKit::OWNER_EQUALITY
      DashKit.available_sources_for = DashKit::NO_SOURCES
    end

    def configure_viewer(viewer)
      controller.define_singleton_method(:dash_kit_test_viewer) { viewer }
      DashKit.current_viewer_method = :dash_kit_test_viewer
    end

    test "dash_kit_editable? is true when the current viewer owns the dashboard" do
      account = Account.create!(name: "Owner")
      dashboard = DashKit::Dashboard.create!(name: "D", dashboard_type: "test_dashboard", owner: account)
      configure_viewer(account)

      assert dash_kit_editable?(dashboard)
    end

    test "dash_kit_editable? is false when the viewer does not own the dashboard" do
      dashboard = DashKit::Dashboard.create!(name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner"))
      configure_viewer(Account.create!(name: "Other"))

      refute dash_kit_editable?(dashboard)
    end

    test "dash_kit_shareable? reflects the host shareable predicate" do
      dashboard = DashKit::Dashboard.create!(name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner"))
      configure_viewer(Account.create!(name: "Other"))
      DashKit.shareable_by = ->(_dashboard, _viewer) { true }

      assert dash_kit_shareable?(dashboard)
    end

    test "dash_kit_viewable? reflects the host viewable predicate" do
      dashboard = DashKit::Dashboard.create!(name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner"))
      configure_viewer(Account.create!(name: "Other"))
      DashKit.viewable_by = ->(_dashboard, _viewer) { true }

      assert dash_kit_viewable?(dashboard)
    end

    test "dash_kit_render_widgets embeds the dashboard id in each widget frame src" do
      dashboard = DashKit::Dashboard.create!(
        name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner"),
        widget_order: %w[stats], hidden_widgets: []
      )

      html = dash_kit_render_widgets(config: dashboard)

      assert_match "dashboard_id=#{dashboard.id}", html
    end

    test "dash_kit_filter_select pre-selects the stored filter value" do
      dashboard = DashKit::Dashboard.create!(
        name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner"),
        filter_state: { "time_period" => "last_7_days" }
      )

      html = dash_kit_filter_select(config: dashboard, key: "time_period",
        options: [ [ "Last 7 days", "last_7_days" ], [ "Last 30 days", "last_30_days" ] ])

      assert_match(/<option selected[^>]*value="last_7_days"|<option value="last_7_days" selected/, html)
    end

    test "dash_kit_filter_select posts to the dashboard save_filters path" do
      dashboard = DashKit::Dashboard.create!(
        name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner")
      )

      html = dash_kit_filter_select(config: dashboard, key: "time_period", options: [ [ "Last 7 days", "last_7_days" ] ])

      assert_match(/action="#{Regexp.escape(dash_kit.save_filters_dashboard_path(dashboard))}"/, html)
    end

    test "dash_kit_filter_select auto-submits when the selection changes" do
      dashboard = DashKit::Dashboard.create!(
        name: "D", dashboard_type: "test_dashboard", owner: Account.create!(name: "Owner")
      )

      html = dash_kit_filter_select(config: dashboard, key: "time_period", options: [ [ "Last 7 days", "last_7_days" ] ])

      assert_match(/onchange="this\.form\.requestSubmit\(\)"/, html)
    end

    test "dash_kit_widget_label returns label from registry" do
      assert_equal "Stats", dash_kit_widget_label(@config, :stats)
    end

    test "dash_kit_widget_label falls back to humanized key" do
      assert_equal "Unknown widget", dash_kit_widget_label(@config, :unknown_widget)
    end

    test "dash_kit_loading_skeleton renders a ui_panel with pulse animation" do
      html = dash_kit_loading_skeleton
      assert_match "animate-pulse", html
    end

    test "dash_kit_settings_button_attributes returns hash with modal action" do
      attrs = dash_kit_settings_button_attributes
      assert_equal "button", attrs[:type]
      assert_equal "click->modal#open", attrs[:data][:action]
    end

    test "dash_kit_settings_modal renders modal with widget toggles" do
      html = dash_kit_settings_modal(config: @config)
      assert_match "dashboard-settings-modal", html
      assert_match "Stats", html
      assert_match "Chart", html
    end

    test "dash_kit_render_widgets renders a built definition frame" do
      definition = @config.widget_definitions.create!(source: "revenue", visualization: "single_value")

      html = dash_kit_render_widgets(config: @config)

      assert_match "widget_definition_#{definition.id}", html
    end

    test "dash_kit_available_sources returns the host sources for the current viewer" do
      viewer = Account.create!(name: "Analyst")
      configure_viewer(viewer)
      DashKit.available_sources_for = ->(v) { v == viewer ? %w[revenue expenses] : [] }

      assert_equal %w[revenue expenses], dash_kit_available_sources
    end

    test "dash_kit_widget_definition_frame lazily loads the definition path" do
      definition = @config.widget_definitions.create!(source: "revenue", visualization: "single_value")

      html = dash_kit_widget_definition_frame(definition)

      assert_match dash_kit.widget_definition_path(definition, dashboard_id: @config.id), html
    end
  end
end
