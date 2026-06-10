# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :accounts, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :dash_kit_configurations, force: true do |t|
    t.references :owner, polymorphic: true, null: false
    t.string :dashboard_type, null: false
    t.json :widget_order, default: []
    t.json :hidden_widgets, default: []
    t.json :widget_settings, default: {}
    t.json :filter_state, default: {}
    t.timestamps
  end

  add_index :dash_kit_configurations, [ :owner_type, :owner_id, :dashboard_type ],
    unique: true, name: "index_dash_kit_configs_on_owner_and_type"

  create_table :dash_kit_dashboards, force: true do |t|
    t.references :owner, polymorphic: true, null: false
    t.bigint :account_id
    t.string :name
    t.string :dashboard_type, null: false
    t.json :widget_order, default: []
    t.json :hidden_widgets, default: []
    t.json :widget_settings, default: {}
    t.json :filter_state, default: {}
    t.string :visibility, null: false, default: "private"
    t.string :role_default_for
    t.boolean :active, null: false, default: false
    t.timestamps
  end

  add_index :dash_kit_dashboards, [ :owner_type, :owner_id ]
  add_index :dash_kit_dashboards, :account_id
end
