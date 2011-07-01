require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
  t.verbose = false
end

# Add running specs to the gem tasks
[:build, :install, :release].each do |task_name|
  bundler_task = Rake::Task[task_name]
  task "bundler_#{task_name}" do
    bundler_task
  end
  task task_name => [:spec, "bundler_#{task_name}"]
end

