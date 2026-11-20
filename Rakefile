require "rake/testtask"
require "bundler/gem_tasks" if File.exist?("Gemfile.lock")

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.test_files = FileList["test/*_test.rb"]
end

task default: :test
