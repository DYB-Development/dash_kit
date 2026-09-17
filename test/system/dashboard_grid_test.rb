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

  test "a dashboard draws its widgets on a grid a viewer can take hold of" do
    visit "/dashboards/#{@dashboard.id}"

    assert_selector "[data-block] [data-block-handle]"
  end
end
