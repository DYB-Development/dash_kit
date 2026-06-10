# frozen_string_literal: true

module DashKit
  class Configuration < ApplicationRecord
    include WidgetManagement

    self.table_name = "dash_kit_configurations"

    belongs_to :owner, polymorphic: true

    validates :dashboard_type, presence: true

    def self.for_owner(owner, dashboard_type)
      find_or_initialize_by(owner: owner, dashboard_type: dashboard_type.to_s) do |config|
        config.widget_order = DashKit.registry.default_widget_order(dashboard_type)
        config.hidden_widgets = []
        config.filter_state = {}
      end
    end
  end
end
