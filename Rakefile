require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

begin
  require "dash_kit/the_local"
  require "the_local/rake"
rescue LoadError
  # the_local provides the_local:build/install tasks when present.
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
