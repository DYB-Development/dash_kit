# frozen_string_literal: true

module DashKit
  class Dashboard < ApplicationRecord
    self.table_name = "dash_kit_dashboards"

    VISIBILITIES = %w[private account].freeze

    belongs_to :owner, polymorphic: true

    validates :name, presence: true
    validates :dashboard_type, presence: true
    validates :visibility, inclusion: { in: VISIBILITIES }
  end
end
