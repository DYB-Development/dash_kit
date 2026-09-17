# frozen_string_literal: true

module DashKit
  class WidgetRegistry
    BUILT_WIDGET = :built_widget
    FULL_WIDTH = 12
    ROWS = 4

    def initialize
      @dashboards = {}
    end

    def register(dashboard_type, &block)
      builder = DashboardBuilder.new
      block.call(builder)
      @dashboards[dashboard_type.to_sym] = builder.widgets.freeze
      register_block_types(dashboard_type)
    end

    def widgets_for(dashboard_type)
      @dashboards.fetch(dashboard_type.to_sym)
    end

    def default_widget_order(dashboard_type)
      widgets_for(dashboard_type)
        .sort_by { |_, v| v[:position] }
        .map { |k, _| k.to_s }
    end

    def widget_label(dashboard_type, widget_key)
      widgets_for(dashboard_type).dig(widget_key.to_sym, :label)
    end

    def widget_partial(dashboard_type, widget_key)
      widgets_for(dashboard_type).dig(widget_key.to_sym, :partial)
    end

    def dashboard_types
      @dashboards.keys
    end

    private

    def register_block_types(dashboard_type)
      KsBlocks.block(BUILT_WIDGET, name: "Built widget", kind: dashboard_type.to_sym, width: FULL_WIDTH, height: ROWS, narrow_width: FULL_WIDTH, narrow_height: ROWS)

      widgets_for(dashboard_type).each do |key, widget|
        KsBlocks.block(key, name: widget[:label], kind: dashboard_type.to_sym,
                       width: widget.fetch(:width, FULL_WIDTH), height: widget.fetch(:height, ROWS),
                       narrow_width: widget[:narrow_width], narrow_height: widget[:narrow_height],
                       once: true, resizable: false)
      end
    end
  end

  class DashboardBuilder
    attr_reader :widgets

    def initialize
      @widgets = {}
      @position = 0
    end

    def widget(key, label:, partial:, **options)
      @position += 1
      @widgets[key.to_sym] = { label: label, partial: partial, position: @position }.merge(options)
    end
  end
end
