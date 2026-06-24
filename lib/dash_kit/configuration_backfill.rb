# frozen_string_literal: true

module DashKit
  module ConfigurationBackfill
    def self.run
      Configuration.find_each do |config|
        Dashboard.find_or_create_by!(
          owner: config.owner,
          dashboard_type: config.dashboard_type,
          name: config.dashboard_type.to_s.humanize
        ) do |dashboard|
          dashboard.widget_order = config.widget_order
          dashboard.hidden_widgets = config.hidden_widgets
          dashboard.filter_state = config.filter_state
          dashboard.widget_settings = config.widget_settings
        end
      end
    end
  end
end
