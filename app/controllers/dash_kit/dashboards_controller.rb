# frozen_string_literal: true

module DashKit
  class DashboardsController < DashKit.parent_controller.constantize
    def index
      @dashboards = dashboard_scope.all
    end

    def new
      @dashboard = dashboard_scope.new
    end

    def create
      @dashboard = dashboard_scope.new(dashboard_params)

      if @dashboard.save
        redirect_to dashboards_path, notice: "Dashboard created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def select
      dashboard_scope.find(params[:id]).activate!
      redirect_to dashboards_path
    end

    def duplicate
      dashboard_scope.find(params[:id]).duplicate!
      redirect_to dashboards_path
    end

    def edit
      @dashboard = dashboard_scope.find(params[:id])
    end

    def destroy
      dashboard_scope.find(params[:id]).destroy
      redirect_to dashboards_path
    end

    def update
      @dashboard = dashboard_scope.find(params[:id])

      if @dashboard.update(dashboard_params)
        redirect_to dashboards_path, notice: "Dashboard updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_widget
      widget_dashboard.toggle_widget(params[:widget_key])
      respond_to do |format|
        format.turbo_stream { render_settings_modal }
        format.html { redirect_back fallback_location: main_app.root_path }
      end
    end

    def move_widget
      case params[:direction]
      when "up"
        widget_dashboard.move_widget_up(params[:widget_key])
      when "down"
        widget_dashboard.move_widget_down(params[:widget_key])
      end
      respond_to do |format|
        format.turbo_stream { render_settings_modal }
        format.html { redirect_back fallback_location: main_app.root_path }
      end
    end

    private

    def widget_dashboard
      @widget_dashboard ||= dashboard_scope.find(params[:id])
    end

    def render_settings_modal
      render turbo_stream: turbo_stream.replace(
        "dashboard-settings-modal",
        partial: "dash_kit/dashboards/settings_modal",
        locals: { config: widget_dashboard }
      )
    end

    def dashboard_params
      params.require(:dashboard).permit(:name, :dashboard_type)
    end

    def dashboard_scope
      if DashKit.current_owner_method
        DashKit::Dashboard.for_owner(send(DashKit.current_owner_method))
      else
        DashKit::Dashboard
      end
    end
  end
end
