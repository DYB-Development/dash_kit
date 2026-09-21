# frozen_string_literal: true

require "ks_blocks/layout_helper"
require "ks_blocks/content_helper"
require "keystone_ui/react/mount_helper"

module DashKit
  module DashboardHelper
    include KsBlocks::LayoutHelper
    include KsBlocks::ContentHelper
    include KeystoneUi::React::MountHelper

    def dash_kit_viewable?(config)
      DashKit.viewable?(config, dash_kit_current_viewer)
    end

    def dash_kit_editable?(config)
      DashKit.editable?(config, dash_kit_current_viewer)
    end

    def dash_kit_shareable?(config)
      DashKit.shareable?(config, dash_kit_current_viewer)
    end

    def dash_kit_current_viewer
      method = DashKit.current_viewer_method || DashKit.current_owner_method
      method && controller.send(method)
    end

    def dash_kit_available_sources
      DashKit.available_sources(dash_kit_current_viewer)
    end

    def dash_kit_visualizations
      DashKit.visualizations
    end

    def dash_kit_widget_label(config, widget_key)
      config.available_widgets.dig(widget_key.to_sym, :label) || widget_key.to_s.humanize
    end

    def dash_kit_render_widgets(config:)
      return content_tag(:div, "", id: "dashboard-widgets") unless config

      content_tag(:div, id: dash_kit_widgets_id(config)) do
        dash_kit_arrangeable?(config) ? dash_kit_widget_grid(config) : dash_kit_drawn_widgets(config)
      end
    end

    def dash_kit_widgets_id(config)
      "dashboard-widgets-#{config.id}"
    end

    def dash_kit_arrangeable?(config)
      DashKit.editable?(config, dash_kit_current_viewer)
    end

    def dash_kit_widget_grid(config)
      safe_join([
        react_ui("dash_kit/dashboard-grid", config.layout_data.merge(base: dash_kit.dashboard_path(config), token: dash_kit_form_token)),
        block_contents(config.blocks) { |block| dash_kit_block_frame(config, block) }
      ])
    end

    def dash_kit_form_token
      controller.send(:form_authenticity_token) if controller.respond_to?(:form_authenticity_token, true)
    end

    def dash_kit_drawn_widgets(config)
      block_layout(config.blocks, kind: config.dashboard_type.to_sym) do |block|
        dash_kit_block_frame(config, block)
      end
    end

    def dash_kit_block_frame(config, block)
      return dash_kit_widget_frame(block["type"], dashboard_id: config.id) unless block["type"] == WidgetRegistry::BUILT_WIDGET.to_s

      definition = config.widget_definitions.find_by(id: block.dig("content", "definition_id"))
      definition ? dash_kit_widget_definition_frame(definition) : dash_kit_loading_skeleton
    end

    def dash_kit_widget_frame(widget_key, dashboard_id: nil, &block)
      dash_kit_turbo_frame(
        id: "widget_#{widget_key}",
        src: dash_kit.widget_path(widget_key, dashboard_id: dashboard_id),
        &block
      )
    end

    def dash_kit_widget_definition_frame(definition, &block)
      dash_kit_turbo_frame(
        id: "widget_definition_#{definition.id}",
        src: dash_kit.widget_definition_path(definition, dashboard_id: definition.dashboard_id),
        &block
      )
    end

    def dash_kit_turbo_frame(id:, src:, &block)
      loading_content = block ? capture(&block) : dash_kit_loading_skeleton

      content_tag("turbo-frame", loading_content, id: id, src: src, loading: "lazy", target: "_top", style: "display: block")
    end

    def dash_kit_filter_select(config:, key:, options:)
      form_tag dash_kit.save_filters_dashboard_path(config), method: :post do
        safe_join([
          hidden_field_tag("filter_key", key),
          select_tag("filter_value", options_for_select(options, config.filter_state[key.to_s]),
            onchange: "this.form.requestSubmit()")
        ])
      end
    end

    def dash_kit_loading_skeleton
      content_tag(:div, class: "rounded-xl bg-white dark:bg-zinc-800 shadow p-4") do
        content_tag(:div, class: "animate-pulse") do
          safe_join([
            content_tag(:div, "", class: "h-5 bg-gray-200 dark:bg-zinc-700 rounded w-1/3 mb-4"),
            content_tag(:div, class: "space-y-3") do
              safe_join([
                content_tag(:div, "", class: "h-4 bg-gray-200 dark:bg-zinc-700 rounded w-full"),
                content_tag(:div, "", class: "h-4 bg-gray-200 dark:bg-zinc-700 rounded w-5/6"),
                content_tag(:div, "", class: "h-4 bg-gray-200 dark:bg-zinc-700 rounded w-4/6")
              ])
            end
          ])
        end
      end
    end
  end
end
