# frozen_string_literal: true

require "test_helper"

class DashKit::WidgetRegistryTest < Minitest::Test
  def setup
    @registry = DashKit::WidgetRegistry.new
  end

  def test_a_registered_widget_is_a_block_type_carrying_the_sizes_it_renders_at
    @registry.register(:sizes_home) do |d|
      d.widget :revenue, label: "Revenue", partial: "widgets/home/revenue", width: 6, height: 4, narrow_width: 12, narrow_height: 2
    end

    block_type = KsBlocks.registry.block_types(kind: :sizes_home).find { |type| type.key == :revenue }

    assert_equal [ 6, 4, 12, 2 ], [ block_type.width, block_type.height, block_type.narrow_width, block_type.narrow_height ]
  end

  def test_register_dashboard_with_widgets
    @registry.register(:home) do |d|
      d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
    end

    widgets = @registry.widgets_for(:home)
    assert_equal 1, widgets.size
    assert_equal "On Deck", widgets[:on_deck][:label]
    assert_equal "widgets/home/on_deck", widgets[:on_deck][:partial]
    assert_equal 1, widgets[:on_deck][:position]
  end

  def test_default_widget_order
    @registry.register(:home) do |d|
      d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      d.widget :tasks, label: "Tasks", partial: "widgets/home/tasks"
      d.widget :goals, label: "Goals", partial: "widgets/home/goals"
    end

    order = @registry.default_widget_order(:home)
    assert_equal %w[on_deck tasks goals], order
  end

  def test_widget_label
    @registry.register(:home) do |d|
      d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
    end

    assert_equal "On Deck", @registry.widget_label(:home, :on_deck)
    assert_nil @registry.widget_label(:home, :nonexistent)
  end

  def test_widget_partial
    @registry.register(:home) do |d|
      d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
    end

    assert_equal "widgets/home/on_deck", @registry.widget_partial(:home, :on_deck)
    assert_nil @registry.widget_partial(:home, :nonexistent)
  end

  def test_unknown_dashboard_type_raises
    assert_raises(KeyError) { @registry.widgets_for(:nonexistent) }
  end

  def test_dashboard_types
    @registry.register(:home) do |d|
      d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
    end
    @registry.register(:inventory) do |d|
      d.widget :metrics, label: "Metrics", partial: "widgets/inventory/metrics"
    end

    assert_equal %i[home inventory], @registry.dashboard_types
  end

  def test_global_configure
    DashKit.reset_registry!

    DashKit.configure do |config|
      config.register(:home) do |d|
        d.widget :on_deck, label: "On Deck", partial: "widgets/home/on_deck"
      end
    end

    assert_equal %i[home], DashKit.registry.dashboard_types
    assert_equal "On Deck", DashKit.registry.widget_label(:home, :on_deck)
  ensure
    DashKit.reset_registry!
  end
end
