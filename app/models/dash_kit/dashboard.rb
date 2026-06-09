# frozen_string_literal: true

module DashKit
  class Dashboard < ApplicationRecord
    self.table_name = "dash_kit_dashboards"

    belongs_to :owner, polymorphic: true

    validates :name, presence: true
  end
end
