# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @dashboard = DashKit::Dashboard.find(params[:id])
  end

  def elsewhere
    render html: helpers.link_to("Back", "/dashboards/#{DashKit::Dashboard.first.id}").html_safe, layout: true
  end
end
