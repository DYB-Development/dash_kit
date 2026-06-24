# frozen_string_literal: true

module DashKit
  class Dashboard < ApplicationRecord
    include WidgetManagement

    self.table_name = "dash_kit_dashboards"

    VISIBILITIES = %w[private account].freeze

    belongs_to :owner, polymorphic: true
    belongs_to :account, optional: true

    has_many :widget_definitions, -> { order(:id) }, dependent: :destroy

    validates :name, presence: true
    validates :dashboard_type, presence: true
    validates :visibility, inclusion: { in: VISIBILITIES }

    scope :for_account, ->(account) { where(account: account) }
    scope :for_owner, ->(owner) { where(owner: owner) }

    def activate!
      transaction do
        self.class.for_owner(owner).where.not(id: id).update_all(active: false)
        update!(active: true)
      end
    end

    def duplicate!
      copy = dup
      copy.name = "#{name} (copy)"
      copy.active = false
      copy.save!
      copy
    end
  end
end
