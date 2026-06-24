# frozen_string_literal: true

module DashKit
  class WidgetDefinition < ApplicationRecord
    self.table_name = "dash_kit_widget_definitions"

    belongs_to :dashboard
  end
end
