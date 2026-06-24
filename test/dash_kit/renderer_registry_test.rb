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
end
