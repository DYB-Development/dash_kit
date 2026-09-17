module DashKit
  class Engine < ::Rails::Engine
    isolate_namespace DashKit

    initializer "dash_kit.tailwind" do
      next unless Gem.loaded_specs.key?("keystone_ui")

      require "keystone_ui"
      KeystoneUi.configuration.tailwind_sources << root.join("app/views/**/*.erb").to_s
      KeystoneUi.configuration.tailwind_sources << root.join("app/assets/builds/dash_kit/*.js").to_s
    end

    initializer "dash_kit.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
      end
    end
  end
end
