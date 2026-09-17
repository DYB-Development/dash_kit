# frozen_string_literal: true

module DashKit
  module WidgetManagement
    extend ActiveSupport::Concern

    def available_widgets
      DashKit.registry.widgets_for(dashboard_type.to_sym)
    end

    def update_filter(key, value)
      self.filter_state = filter_state.merge(key.to_s => value)
      save!
    end
  end
end
