# frozen_string_literal: true

require "test_helper"

class DashKit::WidgetsControllerParentControllerTest < ActionDispatch::IntegrationTest
  class HostController < ActionController::Base
    def current_account
      Account.first
    end
  end

  setup do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      end
    end
    @account = Account.create!(name: "Acme")
    @original_parent = DashKit.parent_controller
    DashKit.current_owner_method = :current_account
    DashKit.parent_controller = "#{self.class.name}::HostController"
    reload_widgets_controller
  end

  teardown do
    DashKit.current_owner_method = nil
    DashKit.parent_controller = @original_parent
    reload_widgets_controller
  end

  test "renders a widget through the host parent controller that supplies the owner method" do
    dashboard = DashKit::Dashboard.create!(
      name: "Home", owner: @account, dashboard_type: "home",
      widget_order: %w[on_deck], hidden_widgets: [], filter_state: {}
    )

    get dash_kit.widget_path(:on_deck, dashboard_id: dashboard.id)

    assert_response :success
  end

  private

  def reload_widgets_controller
    DashKit.send(:remove_const, :WidgetsController) if DashKit.const_defined?(:WidgetsController, false)
    load DashKit::Engine.root.join("app/controllers/dash_kit/widgets_controller.rb").to_s
  end
end
