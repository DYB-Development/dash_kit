require "dash_kit/version"
require "dash_kit/widget_registry"
require "dash_kit/renderer_registry"
require "dash_kit/configuration_backfill"

module DashKit
  class Error < StandardError; end

  mattr_accessor :parent_controller, default: "DashKit::ApplicationController"
  mattr_accessor :current_owner_method, default: nil
  mattr_accessor :current_viewer_method, default: nil

  OWNER_EQUALITY = ->(dashboard, viewer) { dashboard.owner == viewer }
  NO_SOURCES = ->(_viewer) { [] }

  mattr_accessor :viewable_by, default: OWNER_EQUALITY
  mattr_accessor :editable_by, default: OWNER_EQUALITY
  mattr_accessor :shareable_by, default: OWNER_EQUALITY
  mattr_accessor :available_sources_for, default: NO_SOURCES

  def self.available_sources(viewer)
    available_sources_for.call(viewer)
  end

  def self.viewable?(dashboard, viewer)
    viewable_by.call(dashboard, viewer)
  end

  def self.editable?(dashboard, viewer)
    editable_by.call(dashboard, viewer)
  end

  def self.shareable?(dashboard, viewer)
    shareable_by.call(dashboard, viewer)
  end

  def self.registry
    @registry ||= WidgetRegistry.new
  end

  def self.configure
    yield registry
  end

  def self.reset_registry!
    @registry = WidgetRegistry.new
  end

  def self.renderers
    @renderers ||= RendererRegistry.new
  end

  def self.register_renderer(visualization, partial:)
    renderers.register(visualization, partial: partial)
  end

  def self.renderer_for(visualization)
    renderers.renderer_for(visualization)
  end

  def self.visualizations
    renderers.visualizations
  end

  def self.reset_renderers!
    @renderers = RendererRegistry.new
  end
end

require "dash_kit/engine" if defined?(Rails::Engine)
require "dash_kit/the_local"
