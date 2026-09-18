# frozen_string_literal: true

module DashKitViewer
  def dash_kit_viewer
    DashKit::Dashboard.find_by(id: params[:id] || params[:dashboard_id])&.owner
  end
end

ActiveSupport.on_load(:action_controller_base) { include DashKitViewer }

class ApplicationController < ActionController::Base
  helper DashKit::DashboardHelper
end
