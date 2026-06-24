# frozen_string_literal: true

module DashKit
  module ConfigurationBackfill
    class LegacyConfiguration < ActiveRecord::Base
      self.table_name = "dash_kit_configurations"
    end

    def self.run
      LegacyConfiguration.find_each do |config|
        Dashboard.find_or_create_by!(
          owner_type: config.owner_type,
          owner_id: config.owner_id,
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
