# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper DashKit::DashboardHelper

  def dash_kit_viewer
    DashKit::Dashboard.find_by(id: params[:id])&.owner
  end
end
