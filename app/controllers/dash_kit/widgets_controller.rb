# frozen_string_literal: true

module DashKit
  class WidgetsController < DashKit.parent_controller.constantize
    def show
      widget_key = params[:id].to_sym
      widget_def = find_widget_definition(widget_key)

      if widget_def.nil?
        head :not_found
      else
        render partial: widget_def[:partial], layout: false, locals: { filter_state: filter_state }
      end
    end

    private

    def filter_state
      dashboard = dashboard_scope.find_by(id: params[:dashboard_id])
      dashboard ? dashboard.filter_state : {}
    end

    def dashboard_scope
      if DashKit.current_owner_method
        DashKit::Dashboard.for_owner(send(DashKit.current_owner_method))
      else
        DashKit::Dashboard
      end
    end

    def find_widget_definition(key)
      DashKit.registry.dashboard_types.each do |type|
        widgets = DashKit.registry.widgets_for(type)
        return widgets[key] if widgets.key?(key)
      end
      nil
    end
  end
end
