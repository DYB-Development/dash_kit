require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

begin
  require "the_local/rake"
rescue LoadError
  # the_local provides its authoring tasks when present.
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
