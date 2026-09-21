# frozen_string_literal: true

require "test_helper"

class DashKit::DashboardTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test")
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

  test "requires a name" do
    dashboard = DashKit::Dashboard.new(dashboard_type: "home", owner: @account)

    dashboard.valid?

    assert_includes dashboard.errors[:name], "can't be blank"
  end

  test "requires a dashboard_type" do
    dashboard = DashKit::Dashboard.new(name: "Sales", owner: @account)

    dashboard.valid?

    assert_includes dashboard.errors[:dashboard_type], "can't be blank"
  end

  test "allows multiple dashboards per owner and type" do
    DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    second = DashKit::Dashboard.new(name: "Fulfillment", dashboard_type: "stats", owner: @account)

    assert second.valid?
  end

  test "defaults visibility to private" do
    dashboard = DashKit::Dashboard.new

    assert_equal "private", dashboard.visibility
  end

  test "rejects an unknown visibility" do
    dashboard = DashKit::Dashboard.new(name: "Sales", dashboard_type: "stats", owner: @account, visibility: "world")

    dashboard.valid?

    assert_includes dashboard.errors[:visibility], "is not included in the list"
  end

  test "for_account returns only that account's dashboards" do
    other = Account.create!(name: "Other")
    mine = DashKit::Dashboard.create!(name: "Mine", dashboard_type: "stats", owner: @account, account: @account)
    DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other, account: other)

    assert_equal [ mine ], DashKit::Dashboard.for_account(@account).to_a
  end

  test "for_owner returns only that owner's dashboards" do
    other = Account.create!(name: "Other")
    mine = DashKit::Dashboard.create!(name: "Mine", dashboard_type: "stats", owner: @account)
    DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other)

    assert_equal [ mine ], DashKit::Dashboard.for_owner(@account).to_a
  end

  test "activate! marks the dashboard active" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    dashboard.activate!

    assert dashboard.active?
  end

  test "activate! deactivates the owner's other dashboards" do
    current = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account, active: true)
    other = DashKit::Dashboard.create!(name: "Fulfillment", dashboard_type: "stats", owner: @account)

    other.activate!

    assert_not current.reload.active?
  end

  test "activate! leaves another owner's active dashboard untouched" do
    other_owner = Account.create!(name: "Other")
    theirs = DashKit::Dashboard.create!(name: "Theirs", dashboard_type: "stats", owner: other_owner, active: true)
    mine = DashKit::Dashboard.create!(name: "Mine", dashboard_type: "stats", owner: @account)

    mine.activate!

    assert theirs.reload.active?
  end

  test "duplicate! creates a persisted copy" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert dashboard.duplicate!.persisted?
  end

  test "duplicate! assigns the copy to the same owner" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert_equal @account, dashboard.duplicate!.owner
  end

  test "duplicate! copies the source's widget order" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account, widget_order: %w[revenue leads])

    assert_equal %w[revenue leads], dashboard.duplicate!.widget_order
  end

  test "duplicate! names the copy after the source" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account)

    assert_equal "Sales (copy)", dashboard.duplicate!.name
  end

  test "duplicate! leaves the copy inactive when the source is active" do
    dashboard = DashKit::Dashboard.create!(name: "Sales", dashboard_type: "stats", owner: @account, active: true)

    assert_not dashboard.duplicate!.active?
  end

  test "available_widgets returns the registered widgets for its type" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      end
    end
    dashboard = DashKit::Dashboard.new(dashboard_type: "home")

    assert_equal %i[on_deck], dashboard.available_widgets.keys
  end

  test "update_filter merges into filter_state and persists" do
    register_home_widgets
    dashboard = DashKit::Dashboard.create!(
      name: "Home", owner: @account, dashboard_type: "home",
      widget_order: %w[on_deck tasks goals], hidden_widgets: [],
      filter_state: { "time_period" => "last_30_days" }
    )

    dashboard.update_filter(:time_period, "last_7_days")

    assert_equal "last_7_days", dashboard.reload.filter_state["time_period"]
  end

  def test_a_dashboard_keeps_a_block_added_to_its_layout
    DashKit.configure do |config|
      config.register(:layout_home) { |d| d.widget :revenue, label: "Revenue", partial: "widgets/home/revenue", width: 6, height: 4 }
    end
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Mine", dashboard_type: "layout_home")
    revenue = KsBlocks.registry.block_types(kind: :layout_home).find { |type| type.key == :revenue }

    dashboard.add_block(revenue, x: 0, y: 0)

    assert_equal [ [ "revenue", 0, 0, 6, 4 ] ], dashboard.reload.blocks.map { |block| block.values_at("type", "x", "y", "w", "h") }
  end
  test "a dashboard refuses a second widget of the same type" do
    DashKit.configure do |config|
      config.register(:once_home) { |d| d.widget :revenue, label: "Revenue", partial: "widgets/home/revenue", width: 6, height: 4 }
    end
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Mine", dashboard_type: "once_home")
    revenue = KsBlocks.registry.block_types(kind: :once_home).find { |type| type.key == :revenue }
    dashboard.add_block(revenue, x: 0, y: 0)

    assert_raises(KsBlocks::InvalidLayout) { dashboard.add_block(revenue, x: 6, y: 0) }
  end

  test "a dashboard is drawn at the grid its dashboard type declared" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:sized) do |d|
        d.grid columns: 6, row_height: 40, gap: 4
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      end
    end
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Sized", dashboard_type: "sized")

    assert_equal [ 6, 40, 4 ], dashboard.layout_data[:grid].values_at(:columns, :row_height, :gap)
  end

  test "a dashboard is drawn at the narrow column count its dashboard type declared" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:narrowed) do |d|
        d.grid columns: 12, narrow_columns: 4
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      end
    end
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Narrowed", dashboard_type: "narrowed")

    assert_equal 4, dashboard.layout_data[:grid][:narrow_columns]
  end

  test "two dashboard types are each drawn at the grid they declared" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:wide_type) { |d| d.grid(columns: 12); d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck" }
      config.register(:tight_type) { |d| d.grid(columns: 3); d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck" }
    end
    wide = DashKit::Dashboard.create!(owner: @account, name: "Wide", dashboard_type: "wide_type")
    tight = DashKit::Dashboard.create!(owner: @account, name: "Tight", dashboard_type: "tight_type")

    assert_equal [ 12, 3 ], [ wide.layout_data[:grid][:columns], tight.layout_data[:grid][:columns] ]
  end

  test "a dashboard type that declares no grid is drawn at twelve columns of sixty pixel rows with a ten pixel gap" do
    register_home_widgets
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Home", dashboard_type: "home")

    assert_equal [ 12, 60, 10 ], dashboard.layout_data[:grid].values_at(:columns, :row_height, :gap)
  end

  test "a dashboard saved before a widget's height changed is drawn at the new height" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:resized) { |d| d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck", width: 3, height: 4 }
    end
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Resized", dashboard_type: "resized")
    dashboard.add_block(KsBlocks.registry.block_types(kind: :resized).find { |type| type.key == :on_deck }, x: 0, y: 0)

    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:resized) { |d| d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck", width: 3, height: 2 }
    end

    assert_equal 2, dashboard.reload.layout_data[:blocks].first["h"]
  end

  test "a block whose type is no longer registered is drawn at the size saved with it" do
    DashKit.reset_registry!
    DashKit.configure do |config|
      config.register(:retiring) { |d| d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck", width: 3, height: 4 }
    end
    dashboard = DashKit::Dashboard.create!(owner: @account, name: "Retiring", dashboard_type: "retiring")
    dashboard.update!(blocks: [ { "id" => "gone", "type" => "retired_widget", "x" => 0, "y" => 0, "w" => 5, "h" => 7 } ])

    assert_equal [ 5, 7 ], dashboard.reload.layout_data[:blocks].first.values_at("w", "h")
  end
end
