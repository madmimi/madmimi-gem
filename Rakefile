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
    gem.authors = ["Nicholas Young", "Marc Heiligers"]
    gem.add_dependency "crack", "0.1.7"
    gem.add_development_dependency "jeweler", "1.4.0"
    gem.add_development_dependency "fakeweb", ">1.2"
    gem.add_development_dependency "shoulda", ">2.10"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "madmimi #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
