require_relative "lib/dash_kit/version"

Gem::Specification.new do |spec|
  spec.name        = "dash_kit"
  spec.version     = DashKit::VERSION
  spec.authors     = [ "Tyler Schneider" ]
  spec.email       = [ "tylercschneider@gmail.com" ]
  spec.homepage    = "https://github.com/DYB-Development/dash_kit"
  spec.summary     = "A Rails engine for composable, configurable dashboards and widgets."
  spec.description = "DashKit provides a presentation layer for building reusable dashboards. " \
                     "Register widgets, persist user configuration, and render dashboards " \
                     "without coupling to any specific data backend."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/DYB-Development/dash_kit"
  spec.metadata["changelog_uri"] = "https://github.com/DYB-Development/dash_kit/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "keystone_ui", ">= 0.4.1"
end
