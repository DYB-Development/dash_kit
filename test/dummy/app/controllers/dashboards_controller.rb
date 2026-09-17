# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @dashboard = DashKit::Dashboard.find(params[:id])
  end
end
