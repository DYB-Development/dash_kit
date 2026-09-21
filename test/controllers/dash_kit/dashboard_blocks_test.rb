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
    test "a move sends no size, so a block keeps the size stored with it" do
      block = @dashboard.blocks.first

      patch dash_kit.blocks_dashboard_path(@dashboard),
        params: { layout: [ { id: block["id"], x: 6, y: 2, w: 6, h: 2 } ] }, as: :json

      assert_equal [ 6, 2, 6, 4 ], @dashboard.reload.blocks.first.values_at("x", "y", "w", "h")
    end

    test "a widget added from the grid is put on the dashboard" do
      empty = Dashboard.create!(owner: @dashboard.owner, name: "Empty", dashboard_type: "moved_home")

      post dash_kit.blocks_dashboard_path(empty), params: { type: "revenue" }, as: :json

      assert_equal %w[revenue], empty.reload.blocks.map { |block| block["type"] }
    end
    test "a widget removed from the grid is taken off the dashboard" do
      block = @dashboard.blocks.first

      delete dash_kit.block_dashboard_path(@dashboard, block_id: block["id"]), as: :json

      assert_empty @dashboard.reload.blocks
    end

    test "the grid can read the dashboard's layout back" do
      get dash_kit.layout_dashboard_path(@dashboard), as: :json

      assert_equal @dashboard.blocks.map { |block| block["id"] }, response.parsed_body["blocks"].map { |block| block["id"] }
    end
    test "the layout carries each block's markup, so a block added after the page loaded draws its card" do
      get dash_kit.layout_dashboard_path(@dashboard), as: :json

      assert_includes response.parsed_body["contents"].fetch(@dashboard.blocks.first["id"]), "turbo-frame"
    end

    test "a built widget block with no definition yet does not break the layout" do
      @dashboard.update!(blocks: @dashboard.blocks + [ { "id" => "fresh", "type" => "built_widget", "x" => 0, "y" => 4, "w" => 12, "h" => 4 } ])

      get dash_kit.layout_dashboard_path(@dashboard), as: :json

      assert_response :success
    end

    test "someone who may not edit the dashboard is refused a move" do
      DashKit.editable_by = ->(_dashboard, _viewer) { false }
      DashKit::ApplicationController.class_eval { def dash_kit_watcher; "watcher"; end }
      DashKit.current_viewer_method = :dash_kit_watcher
      block = @dashboard.blocks.first

      patch dash_kit.blocks_dashboard_path(@dashboard),
        params: { layout: [ { id: block["id"], x: 6, y: 2, w: block["w"], h: block["h"] } ] }, as: :json

      assert_response :forbidden
    ensure
      DashKit.current_viewer_method = nil
      DashKit.editable_by = DashKit::OWNER_EQUALITY
      DashKit::ApplicationController.send(:remove_method, :dash_kit_watcher)
    end
  end
end
