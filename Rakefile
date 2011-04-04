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
  stashed = false
  tmp_doc = Dir.mktmpdir 'onstomp_docs'
  puts "Generating yard docs in temp dir #{tmp_doc}"
  `rake yard OPTS="--output-dir #{tmp_doc}"`
  `git diff-files --quiet`
  if $?.exitstatus == 1
    # we have changes
    puts "Stashing your working changes"
    stashed = true
    `git stash save "stashing changes for gh-pages update"`
  end
  sh "git checkout gh-pages"
  sh "git pull origin gh-pages"
  rm_rf [ Dir.glob("*.html"), "OnStomp", "js", "css" ].flatten
  cp_r "#{tmp_doc}/.", '.'
  new_docs = Dir.glob("#{tmp_doc}/**/*").map { |f| f.sub(tmp_doc + '/','') }
  rm_rf tmp_doc
  removed_docs = `git status --porcelain --untracked-files=no|grep "^ D "`.split("\n").map do |line|
    line[3..-1]
  end
  puts "Adding changed documentation"
  `git add #{new_docs.join(' ')}`
  unless removed_docs.empty?
    puts "Cleaning out old doc files"
    `git rm #{removed_docs.join(' ')}`
  end
  sh "git commit -m \"updated yard docs\""
  puts "Pushing changes to remote 'origin/gh-pages'"
  `git push origin gh-pages`
  if $?.exitstatus == 1
    puts "Updates could not be pushed to remote, resolve the conflict then:"
    puts "\tgit push origin gh-pages"
    puts "\tgit checkout master"
    puts "\tgit stash pop" if stashed
  else
    `git checkout master`
    if stashed
      puts "Restoring your working copy changes"
      `git stash pop`
    end
  end
end
