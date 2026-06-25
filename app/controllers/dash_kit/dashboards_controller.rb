# frozen_string_literal: true

module DashKit
  class DashboardsController < DashKit.parent_controller.constantize
    before_action :require_editable!, only: %i[toggle_widget move_widget reorder save_filters create_definition]

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

    def reorder
      new_order = params[:widget_order]
      valid_keys = widget_dashboard.available_widgets.keys.map(&:to_s)

      if new_order.is_a?(Array) && new_order.all? { |k| valid_keys.include?(k) }
        attrs = { widget_order: new_order }
        attrs[:hidden_widgets] = params[:hidden_widgets] if params[:hidden_widgets].is_a?(Array)
        widget_dashboard.update!(attrs)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def save_filters
      widget_dashboard.update_filter(params[:filter_key], params[:filter_value])
      respond_to do |format|
        format.turbo_stream { render_widgets }
        format.html { redirect_back fallback_location: main_app.root_path }
      end
    end

    def create_definition
      widget_dashboard.widget_definitions.create(definition_params)
      respond_to do |format|
        format.turbo_stream { render_widgets }
        format.html { redirect_back fallback_location: main_app.root_path }
      end
    end

    private

    def definition_params
      params.require(:widget_definition).permit(:source, :visualization, options: {})
    end

    def widget_dashboard
      @widget_dashboard ||= dashboard_scope.find(params[:id])
    end

    def render_widgets
      render turbo_stream: turbo_stream.replace(
        "dashboard-widgets",
        partial: "dash_kit/dashboards/widgets",
        locals: { config: widget_dashboard }
      )
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

    def require_editable!
      viewer = current_viewer
      return if viewer.nil?

      head :forbidden unless DashKit.editable?(widget_dashboard, viewer)
    end

    def current_viewer
      if DashKit.current_viewer_method
        send(DashKit.current_viewer_method)
      elsif DashKit.current_owner_method
        send(DashKit.current_owner_method)
      end
    end
  end
end
