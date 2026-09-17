# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "propshaft"

Bundler.require(*Rails.groups)
require "turbo-rails"
require "keystone_ui"
require "dash_kit"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.secret_key_base = "test_secret_key_base_for_dash_kit_gem"
  end
end
