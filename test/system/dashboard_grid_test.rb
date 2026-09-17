require "timeout"
# frozen_string_literal: true

require "application_system_test_case"

class DashboardGridTest < ApplicationSystemTestCase
  setup do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:stats) { |d| d.widget :revenue, label: "Revenue", partial: "widgets/home/revenue", width: 6, height: 4 }
    end
    DashKit.current_viewer_method = :dash_kit_viewer
    @dashboard = DashKit::Dashboard.create!(owner: Account.create!(name: "Watcher"), name: "Stats", dashboard_type: "stats")
    @dashboard.add_block(KsBlocks.registry.block_types(kind: :stats).find { |type| type.key == :revenue }, x: 0, y: 0)
  end

  teardown do
    DashKit.current_viewer_method = nil
  end

  test "a dashboard draws its widgets on a grid a viewer can take hold of" do
    visit "/dashboards/#{@dashboard.id}"

    assert_selector "[data-block] [data-block-handle]"
  end
  test "a widget moved by its handle stays where it was put after a reload" do
    visit "/dashboards/#{@dashboard.id}"
    widget = find("[data-block]")
    handle = widget.find("[data-block-handle]")

    page.driver.browser.action.click_and_hold(handle.native).move_by(300, 0).move_by(300, 0).release.perform
    Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.05 until @dashboard.reload.blocks.first["x"].positive? }
    refresh

    assert_operator @dashboard.reload.blocks.first["x"], :>, 0
  end
  test "the grid is drawn again when the dashboard is reached a second time" do
    visit "/dashboards/#{@dashboard.id}"
    find("[data-block-handle]")

    click_on "Elsewhere"
    click_on "Back"

    assert_selector "[data-block] [data-block-handle]"
  end
end
