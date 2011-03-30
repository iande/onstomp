require 'bundler'
Bundler::GemHelper.install_tasks

require 'yard'
require File.expand_path("../yard_extensions", __FILE__)
YARD::Rake::YardocTask.new

require 'rspec/core/rake_task'
desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end

task :default => :spec