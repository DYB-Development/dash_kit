# frozen_string_literal: true

require "test_helper"

class DashKit::RendererRegistryTest < Minitest::Test
  def setup
    @registry = DashKit::RendererRegistry.new
  end

  def test_looks_up_a_registered_renderer
    @registry.register(:single_value, partial: "renderers/single_value")

    assert_equal "renderers/single_value", @registry.renderer_for(:single_value)
  end

  def test_unknown_visualization_returns_nil
    assert_nil @registry.renderer_for(:nonexistent)
  end
end

class DashKit::RegisterRendererTest < Minitest::Test
  def setup
    DashKit.reset_renderers!
  end

  def test_registers_a_renderer_at_the_module_level
    DashKit.register_renderer(:chart, partial: "renderers/chart")

    assert_equal "renderers/chart", DashKit.renderer_for(:chart)
  end
end
