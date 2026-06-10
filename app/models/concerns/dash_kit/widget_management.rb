# frozen_string_literal: true

module DashKit
  module WidgetManagement
    extend ActiveSupport::Concern

    def ordered_visible_widgets
      registered = available_widgets.keys.map(&:to_s)
      widget_order.select { |w| registered.include?(w) }.reject { |w| hidden_widgets.include?(w) }
    end

    def available_widgets
      DashKit.registry.widgets_for(dashboard_type.to_sym)
    end

    def widget_visible?(widget_key)
      !hidden_widgets.include?(widget_key.to_s)
    end

    def toggle_widget(widget_key)
      key = widget_key.to_s
      self.hidden_widgets = if hidden_widgets.include?(key)
        hidden_widgets - [ key ]
      else
        hidden_widgets + [ key ]
      end
      save!
    end

    def move_widget_up(widget_key)
      index = widget_order.index(widget_key.to_s)
      return if index.nil? || index == 0

      new_order = widget_order.dup
      new_order[index], new_order[index - 1] = new_order[index - 1], new_order[index]
      update!(widget_order: new_order)
    end

    def move_widget_down(widget_key)
      index = widget_order.index(widget_key.to_s)
      return if index.nil? || index == widget_order.length - 1

      new_order = widget_order.dup
      new_order[index], new_order[index + 1] = new_order[index + 1], new_order[index]
      update!(widget_order: new_order)
    end

    def update_filter(key, value)
      self.filter_state = filter_state.merge(key.to_s => value)
      save!
    end
  end
end
