# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "heartbeat-client"
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Oliver Kiessler"]
  s.description = "Heartbeat Client in Ruby"
  s.email = "kiessler@inceedo.com"
  s.executables = ["hbc"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "Procfile",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/hbc",
    "heartbeat-client.gemspec",
    "heartbeat-client.yml.sample",
    "lib/heartbeat-client.rb",
    "test/helper.rb",
    "test/test_heartbeat-client.rb"
  ]
  s.homepage = "http://github.com/okiess/heartbeat-client"
  s.licenses = ["MIT"]
  s.summary = "Heartbeat"

  s.add_runtime_dependency "httparty", ">= 0.21.0"
  s.add_runtime_dependency "daemons"
  s.add_runtime_dependency "foreman"
  s.add_runtime_dependency "macaddr"
  s.add_runtime_dependency "keen"

  s.add_development_dependency "shoulda"
  s.add_development_dependency "bundler", ">= 2.2.33"
  s.add_development_dependency "rake", ">= 12.3.3"
  s.add_development_dependency "git", ">= 1.11.0"
  s.add_development_dependency "test-unit", "~> 3.7"
end
