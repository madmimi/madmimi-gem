require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "madmimi"
    gem.summary = %Q{Mad Mimi API wrapper for Ruby}
    gem.description = %Q{Send emails, track statistics, and manage your subscriber base with ease.}
    gem.email = "nicholas@madmimi.com"
    gem.homepage = "http://github.com/madmimi/madmimi-gem"
    gem.authors = ["Nicholas Young", "Marc Heiligers", "Maxim Gladkov"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "madmimi #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
end
