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

desc "Tasks for generating/monitoring APIs and their changes"
task :api do
  puts "Refreshing YARD database"
  `yard doc -n`
  puts "Generating API.md"
  `rake api:gen`
  puts "Updating YARD docs"
  `rake yard`
end

namespace :api do
  def parse_api_spec str
    g_major, s_proto, rest = str.split(' ', 3)
    g_varies = nil
    g_major = g_major[4..-1]
    s_proto = s_proto[6..-1]
    if g_major =~ /[\*\!]$/
      g_varies = g_major.end_with?('!') ? :major : :minor
      g_major = g_major[0..-2]
    end
    if s_proto =~ /[\*\!]$/
      s_varies = s_proto.end_with?('!') ? :major : :minor
      s_proto = s_proto[0..-2]
    end
    {
      :majors => g_major.split(','),
      :stomp_protocols => s_proto.split(','),
      :gem_variations => g_varies,
      :protocol_variations => s_varies,
      :notes => rest
    }
  end
  
  def make_method_tag link, yard_obj
    parse_api_spec(yard_obj.tags.detect { |t| t.tag_name == 'api' }.text).tap do |t|
      t[:name] = yard_obj.name
      t[:signature] = yard_obj.signature.sub(/^def /,'')
      t[:yard_link] = link
    end
  end
  
  def make_signature_tags link, yard_obj
    base = make_method_tag(link, yard_obj)
    overrides = yard_obj.tags.select do |t|
      t.instance_of? ::YARD::Tags::OverloadTag
    end
    if overrides.empty?
      [base]
    else
      overrides.map do |o|
        base.dup.tap do |b|
          b[:signature] = o.signature
          if api_spec = o.tags.detect { |t| t.tag_name == 'api' }
            b.merge! parse_api_spec(api_spec.text)
          end
        end
      end
    end
  end
  
  desc "Generate some API changes"
  task :gen => [:yard] do
    GEM_ROOT = File.expand_path('..', __FILE__)
    TEMPLATE_INPUT = File.join GEM_ROOT, 'extra_doc', 'API.md.erb'
    YARD_DB = File.join GEM_ROOT, '.yardoc', 'objects', 'root.dat'
    TEMPLATE_OUTPUT = File.join GEM_ROOT, 'extra_doc', 'API.md'
    require 'erubis'
    
    template = File.open(TEMPLATE_INPUT, 'rb') { |f| f.read }
    yard_hash = Marshal.load(File.open(YARD_DB, 'rb') { |f| f.read })
    api_set = yard_hash.keys.select { |k| yard_hash[k].tags.any? { |t| t.tag_name == 'api' } }
    api_table = Hash.new do |h,k|
      h[k] = { :version => k, :methods => [] }
    end
    protos = []
    api_set.each do |k|
      yard_obj = yard_hash[k]
      meths = make_signature_tags k.to_s, yard_obj
      meths.each do |m|
        m[:stomp_protocols].each { |p| protos << p unless protos.include?(p) }
        m[:majors].each { |v| api_table[v][:methods] << m }
      end
    end
    protos.sort!
    apis = api_table.keys.sort.map do |k|
      api = {
        :version => k,
        :protocols => protos
      }
      api[:methods] = api_table[k][:methods].map do |m|
        m[:protocols] = protos.map { |p| m[:stomp_protocols].include? p }
        m
      end.sort { |a,b| a[:name] <=> b[:name] }
      api
    end
    erb = Erubis::Eruby.new template
    template = erb.result(binding())
    File.open(TEMPLATE_OUTPUT, 'wb') { |f| f.write template }
  end
  
  desc "Generate yard docs on gh-pages branch and push out to github"
  task :push do
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
end
