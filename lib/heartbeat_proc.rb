require 'rubygems'
require 'daemons'
require 'logger'
require File.dirname(__FILE__) + '/heartbeat-client'

begin
  puts "Using config in your home directory"
  @config = YAML.load(File.read("#{ENV['HOME']}/.heartbeat-client.yml"))
rescue Errno::ENOENT
  raise "heartbeat-client.yml expected in ~/.heartbeat-client.yml"
end

unless @config['apikey']
  puts "API Key not found!"
  exit
end

Daemons.run_proc('heartbeat-client.rb') do
  loop do
    Heartbeat.create(@config['apikey'])
    sleep(30)
  end
end