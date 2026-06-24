# frozen_string_literal: true

module DashKit
  module ConfigurationBackfill
    def self.run
      Configuration.find_each do |config|
        Dashboard.create!(
          owner: config.owner,
          dashboard_type: config.dashboard_type,
          name: config.dashboard_type.to_s.humanize,
          widget_order: config.widget_order,
          hidden_widgets: config.hidden_widgets
        )
      end
    end
  end
end
