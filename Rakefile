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

desc "Generate yard docs on gh-pages branch and push out to github"
task :ghpages do
  require 'tmpdir'
  tmp_doc = Dir.mktmpdir 'onstomp_docs'
  prior_docs = []
  new_docs = []
  puts "Generating yard docs in temp dir #{tmp_doc}"
  `rake yard OPTS="--output-dir #{tmp_doc}"`
  `git stash save "stashing changes for gh-pages update"`
  `git checkout gh-pages`
  `git pull origin gh-pages`
  prior_docs = `git ls-files`.split("\n")
  rm_rf [ Dir.glob("*.html"), "OnStomp", "js", "css" ]
  cp_r "#{tmp_doc}/.", '.'
  new_docs = Dir.glob("#{tmp_doc}/**/*").map { |f| f.sub(tmp_doc + '/','') }
  rm_rf tmp_doc
  removed_docs = prior_docs - new_docs
  `git add #{new_docs.join(' ')}`
  `git rm #{removed_docs.join(' ')}`
  `git commit -m "updated yard docs"`
  `git push origin gh-pages`
  `git checkout master`
  `git stash pop`
end
