# frozen_string_literal: true

require "test_helper"

module DashKit
  class DashboardBlocksTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      DashKit.configure do |config|
        config.register(:moved_home) { |d| d.widget :revenue, label: "Revenue", partial: "widgets/home/revenue", width: 6, height: 4 }
      end
      @dashboard = Dashboard.create!(owner: Account.create!(name: "Mover"), name: "Mine", dashboard_type: "moved_home")
      @dashboard.add_block(KsBlocks.registry.block_types(kind: :moved_home).find { |type| type.key == :revenue }, x: 0, y: 0)
    end

    test "a move a viewer makes on the grid is saved" do
      block = @dashboard.blocks.first

      patch dash_kit.blocks_dashboard_path(@dashboard),
        params: { layout: [ { id: block["id"], x: 6, y: 2, w: block["w"], h: block["h"] } ] }, as: :json

      assert_equal [ 6, 2 ], @dashboard.reload.blocks.first.values_at("x", "y")
    end
  end
end
