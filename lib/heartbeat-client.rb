require 'rubygems'
gem 'httparty'
require 'httparty'
require 'pp'

class Heartbeat
  include HTTParty
  base_uri 'http://heartbeat-server.herokuapp.com' #'http://localhost:5000'
end

options = {
  :body => {
    :heartbeat => {
      :apikey => '8758475893749857398fzhdsjfhuiszr4z84r738thf43zt',
      :host => 'some.host.com',
      :timestamp => Time.now.to_i,
      :values => {
        :cpu => 0,
        :memory_used => 0,
        :memory_free => 0 
      }
    }
  }
}

pp Heartbeat.post('/heartbeat', options)
