# frozen_string_literal: true

module DashKit
  class RendererRegistry
    def initialize
      @renderers = {}
    end

    def register(visualization, partial:)
      @renderers[visualization.to_sym] = partial
    end

    def renderer_for(visualization)
      @renderers[visualization.to_sym]
    end

    def visualizations
      @renderers.keys
    end
  end
end
