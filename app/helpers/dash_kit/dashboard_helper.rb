# frozen_string_literal: true

module DashKit
  module DashboardHelper
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

    def dash_kit_widget_label(config, widget_key)
      config.available_widgets.dig(widget_key.to_sym, :label) || widget_key.to_s.humanize
    end

    def dash_kit_render_widgets(config:)
      return content_tag(:div, "", id: "dashboard-widgets") unless config

      content_tag(:div, id: "dashboard-widgets", class: "space-y-6") do
        safe_join(
          config.ordered_visible_widgets.filter_map do |widget_key|
            widget_def = config.available_widgets[widget_key.to_sym]
            next unless widget_def

            dash_kit_widget_frame(widget_key, dashboard_id: config.id)
          end
        )
      end
    end

    def dash_kit_widget_frame(widget_key, dashboard_id: nil, &block)
      src = dash_kit.widget_path(widget_key, dashboard_id: dashboard_id)
      id = "widget_#{widget_key}"
      loading_content = block ? capture(&block) : dash_kit_loading_skeleton

      content_tag("turbo-frame", loading_content, id: id, src: src, loading: "lazy", target: "_top", style: "display: block")
    end

    def dash_kit_settings_modal(config:)
      render partial: "dash_kit/configurations/settings_modal", locals: { config: config }
    end

    def dash_kit_settings_button_attributes
      {
        type: "button",
        class: "inline-flex items-center rounded-md px-3 py-2 text-sm font-semibold shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
        data: { action: "click->modal#open" }
      }
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
