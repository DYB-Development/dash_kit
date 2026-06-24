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

      @config = DashKit::Configuration.for_owner(Account.create!(name: "Test"), :test_dashboard)
      @config.save!
    end

    teardown do
      DashKit.current_viewer_method = nil
      DashKit.viewable_by = DashKit::OWNER_EQUALITY
      DashKit.editable_by = DashKit::OWNER_EQUALITY
      DashKit.shareable_by = DashKit::OWNER_EQUALITY
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
  end
end
