# frozen_string_literal: true

module DashKit
  class DashboardsController < DashKit.parent_controller.constantize
    def index
      @dashboards = dashboard_scope.all
    end

    private

    def dashboard_scope
      if DashKit.current_owner_method
        DashKit::Dashboard.for_owner(send(DashKit.current_owner_method))
      else
        DashKit::Dashboard
      end
    end
  end
end
