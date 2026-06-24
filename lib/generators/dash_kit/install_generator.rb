# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module DashKit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Install DashKit dashboard engine"

      def copy_migration
        migration_template "create_dash_kit_dashboards.rb.tt", "db/migrate/create_dash_kit_dashboards.rb"
      end

      def copy_initializer
        template "dash_kit.rb.tt", "config/initializers/dash_kit.rb"
      end

      def mount_engine
        route 'mount DashKit::Engine => "/dash_kit"'
      end

      IMPORTMAP_PATH = "config/importmap.rb"
      STIMULUS_INDEX_PATH = "app/javascript/controllers/index.js"

      def pin_sortablejs
        return unless host_file?(IMPORTMAP_PATH)
        return if host_file_includes?(IMPORTMAP_PATH, 'pin "sortablejs"')

        append_to_file IMPORTMAP_PATH, %(pin "sortablejs"\n)
      end

      def register_dash_kit_controllers
        return unless host_file?(STIMULUS_INDEX_PATH)
        return if host_file_includes?(STIMULUS_INDEX_PATH, "registerDashKitControllers")

        append_to_file STIMULUS_INDEX_PATH, <<~JS

          import { registerControllers as registerDashKitControllers } from "dash_kit/index"
          registerDashKitControllers(application)
        JS
      end

      def print_instructions
        say ""
        say "DashKit installed successfully!", :green
        say ""
        say "Pinned sortablejs and registered DashKit's Stimulus controllers for you", :green
        say "(where config/importmap.rb and app/javascript/controllers/index.js exist)."
        say ""
        say "Next steps:", :yellow
        say ""
        say "  1. Run migrations:"
        say "       rails db:migrate"
        say ""
        say "  2. Add the association to your owner model (e.g. Account):"
        say "       has_many :dash_kit_configurations, class_name: \"DashKit::Configuration\","
        say "                as: :owner, dependent: :destroy"
        say ""
        say "  3. Configure parent_controller and current_owner_method in"
        say "     config/initializers/dash_kit.rb"
        say ""
        say "  4. Register your dashboards and widgets in the initializer"
        say ""
      end

      private

      def host_file?(path)
        File.exist?(File.expand_path(path, destination_root))
      end

      def host_file_includes?(path, snippet)
        File.read(File.expand_path(path, destination_root)).include?(snippet)
      end
    end
  end
end
