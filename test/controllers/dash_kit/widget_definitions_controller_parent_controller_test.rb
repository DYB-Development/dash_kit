# frozen_string_literal: true

require "test_helper"

class DashKit::WidgetDefinitionsControllerParentControllerTest < ActionDispatch::IntegrationTest
  class HostController < ActionController::Base
    def current_account
      Account.first
    end
  end

  setup do
    DashKit.reset_renderers!
    DashKit.register_renderer(:single_value, partial: "renderers/single_value")
    @account = Account.create!(name: "Acme")
    @dashboard = DashKit::Dashboard.create!(
      name: "Home", owner: @account, dashboard_type: "home", filter_state: {}
    )
    @original_parent = DashKit.parent_controller
    DashKit.current_owner_method = :current_account
    DashKit.parent_controller = "#{self.class.name}::HostController"
    reload_widget_definitions_controller
  end

  teardown do
    DashKit.reset_renderers!
    DashKit.current_owner_method = nil
    DashKit.parent_controller = @original_parent
    reload_widget_definitions_controller
  end

  test "renders a definition through the host parent controller that supplies the owner method" do
    definition = @dashboard.widget_definitions.create!(source: "revenue", visualization: "single_value")

    get dash_kit.widget_definition_path(definition)

    assert_response :success
  end

  private

  def reload_widget_definitions_controller
    DashKit.send(:remove_const, :WidgetDefinitionsController) if DashKit.const_defined?(:WidgetDefinitionsController, false)
    load DashKit::Engine.root.join("app/controllers/dash_kit/widget_definitions_controller.rb").to_s
  end
end
