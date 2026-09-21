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

    def layout_data
      KsBlocks.layout_data(roomed_blocks, kind: block_layout_kind, grid: declared_grid, offered: block_layout_offered)
        .merge(version: KsBlocks.version_of(blocks))
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

    private

    def roomed_blocks
      rooms = block_layout_types.index_by { |block_type| block_type.key.to_s }

      blocks.map do |block|
        room = rooms[block["type"]]
        room ? block.merge("w" => room.width, "h" => room.height) : block
      end
    end

    def declared_grid
      declared = DashKit.registry.grid_for(dashboard_type)
      columns = declared.fetch(:columns, KsBlocks::Grid::COLUMNS)
      row_height = declared.fetch(:row_height, KsBlocks::Grid::ROW_HEIGHT)
      gap = declared.fetch(:gap, KsBlocks::Grid::GAP)

      {
        columns: columns, row_height: row_height, gap: gap,
        narrow_columns: declared[:narrow_columns] || columns,
        narrow_row_height: declared[:narrow_row_height] || row_height,
        narrow_gap: declared[:narrow_gap] || gap,
        narrow_below: declared.fetch(:narrow_below, KsBlocks::Grid::NARROW_BELOW)
      }
    end
  end
end
