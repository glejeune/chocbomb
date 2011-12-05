require 'rubygems'
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "chocbomb"
  gem.homepage = "http://github.com/glejeune/chocbomb"
  gem.license = "MIT"
  gem.summary = %Q{ChocBomb is a shameful copy of ChocTop}
  gem.description = %Q{ChocBomb is a shameful copy of ChocTop - Build and deploy tools for Cocoa apps using Sparkle for distributions and upgrades; it’s like Hoe but for Cocoa apps.}
  gem.email = "gregoire.lejeune@gmail.com"
  gem.authors = ["glejeune"]
  gem.add_dependency "plist", ">= 3.1.0"
  gem.add_dependency "escape", ">= 0.0.4"
  gem.add_dependency "builder",">=2.1.2"
  gem.add_dependency "RedCloth", ">=4.2.3"
  
  gem.add_development_dependency "jeweler", "~> 1.5.2"
  gem.add_development_dependency "rcov", ">= 0"
  gem.add_development_dependency "rdoc", ">= 0"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "chocbomb #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
