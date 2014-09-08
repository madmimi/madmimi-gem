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
    gem.add_dependency "activesupport", ">3.0.0"
    gem.add_dependency "crack", ">0.1.7"
    gem.add_dependency "httparty", ">=0.13.1"
    gem.add_development_dependency "rspec", ">=3.1.0"
    gem.add_development_dependency "vcr", ">=2.9.3"
    gem.add_development_dependency "webmock", ">=1.18.0"
    gem.add_development_dependency "jeweler", ">1.4"
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
