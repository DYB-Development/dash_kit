# frozen_string_literal: true

require "ks_blocks/layout"

module DashKit
  class Dashboard < ApplicationRecord
    include WidgetManagement
    include KsBlocks::Layout

    self.table_name = "dash_kit_dashboards"

    block_layout :blocks, kind: :blocks

    def block_layout_kind
      dashboard_type.to_sym
    end

    def add_built_widget(definition, x: nil, y: nil)
      built = KsBlocks.registry.block_types(kind: block_layout_kind).find { |type| type.key == WidgetRegistry::BUILT_WIDGET }
      add_block(built, x: x, y: y)
      fill_block(blocks.last["id"], { "definition_id" => definition.id })
    end

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
