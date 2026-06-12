# frozen_string_literal: true

require "test_helper"
require "generators/dash_kit/install_generator"
require "rails/generators/test_case"

class DashKit::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests DashKit::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)

  setup do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(
      File.join(destination_root, "config", "routes.rb"),
      "Rails.application.routes.draw do\nend\n"
    )
  end

  test "creates migration file" do
    run_generator
    assert_migration "db/migrate/create_dash_kit_configurations.rb" do |migration|
      assert_match(/create_table :dash_kit_configurations/, migration)
      assert_match(/t\.references :owner, polymorphic: true/, migration)
      assert_match(/t\.string :dashboard_type/, migration)
      assert_match(/t\.jsonb :widget_order/, migration)
      assert_match(/t\.jsonb :hidden_widgets/, migration)
      assert_match(/index_dash_kit_configs_on_owner_and_type/, migration)
    end
  end

  test "creates initializer" do
    run_generator
    assert_file "config/initializers/dash_kit.rb" do |content|
      assert_match(/DashKit\.configure/, content)
      assert_match(/config\.register/, content)
    end
  end

  test "mounts engine in routes" do
    run_generator
    assert_file "config/routes.rb" do |content|
      assert_match(/mount DashKit::Engine/, content)
    end
  end

  test "pins sortablejs in the importmap" do
    File.write(File.join(destination_root, "config", "importmap.rb"), "# Pin npm packages\n")

    run_generator

    assert_file "config/importmap.rb" do |content|
      assert_match(/pin "sortablejs"/, content)
    end
  end

  test "does not duplicate an already-pinned sortablejs" do
    File.write(File.join(destination_root, "config", "importmap.rb"), %(pin "sortablejs" # @1.15.7\n))

    run_generator

    importmap = File.read(File.join(destination_root, "config", "importmap.rb"))
    assert_equal 1, importmap.scan(/pin "sortablejs"/).length
  end
end
