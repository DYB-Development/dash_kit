# frozen_string_literal: true

module DashKit
  class WidgetDefinitionsController < DashKit.parent_controller.constantize
    def show
      definition = definition_scope.find_by(id: params[:id])
      return head :not_found if definition.nil?

      renderer = DashKit.renderer_for(definition.visualization)
      return render partial: "dash_kit/widget_definitions/missing_renderer", layout: false if renderer.nil?

      render partial: renderer, layout: false, locals: {
        source: definition.source,
        options: definition.options,
        filter_state: definition.dashboard.filter_state
      }
    end

    private

    def definition_scope
      DashKit::WidgetDefinition.where(dashboard: dashboard_scope)
    end

    def dashboard_scope
      if DashKit.current_owner_method
        DashKit::Dashboard.for_owner(send(DashKit.current_owner_method))
      else
        DashKit::Dashboard.all
      end
    end
  end
end
