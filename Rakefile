require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "heartbeat-client"
  gem.homepage = "http://github.com/okiess/heartbeat-client"
  gem.license = "MIT"
  gem.summary = "Heartbeat"
  gem.description = "Heartbeat Client in Ruby"
  gem.email = "kiessler@inceedo.com"
  gem.authors = ["Oliver Kiessler"]
  gem.add_runtime_dependency 'daemons'
  gem.add_runtime_dependency 'httparty'
  gem.add_runtime_dependency 'json'
  gem.add_runtime_dependency 'foreman'
  gem.add_runtime_dependency 'macaddr'
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

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "heartbeat-client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
