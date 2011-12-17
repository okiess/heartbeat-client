require 'rubygems'
gem 'httparty'
require 'httparty'
require 'pp'
require 'logger'

class Heartbeat
  include HTTParty
  base_uri 'http://heartbeat-server.herokuapp.com'

  def self.is_mac?
    RUBY_PLATFORM.downcase.include?("darwin")
  end

  def self.is_linux?
    RUBY_PLATFORM.downcase.include?("linux")
  end
  
  def self.log
    Logger.new('/tmp/heartbeat.log')
  end
  
  def self.create(apikey)
    cpu = 0; load_average = 0; memory_used = 0; memory_free = 0
    output = is_mac? ? `top -l 1`.chomp : `top -n 1`.chomp

    # puts output.split('\n').first.inspect
    # TODO analyse output

    options = {
      :body => {
        :heartbeat => {
          :apikey => apikey,
          :host => `hostname`.chomp,
          :timestamp => Time.now.to_i,
          :values => {
            :cpu => cpu,
            :load_average => load_average,
            :memory_used => memory_used,
            :memory_free => memory_free 
          }
        }
      }
    }

    pp Heartbeat.post('/heartbeat', options)    
    # log.info("Heartbeat sent...")
  end
end
