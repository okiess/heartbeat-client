require 'rubygems'
gem 'httparty'
require 'httparty'
require 'logger'
require 'pp'

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
    procs = {'total' => 0, 'running' => 0, 'stuck' => 0, 'sleeping' => 0, 'threads' => 0}
    load_avg = []
    cpu_usage = {'user' => 0, 'sys' => 0, 'idle' => 0}
    processes = []

    if self.is_linux?
      `top -b -n1 > /tmp/top.out`
    else
      `top -l 1 > /tmp/top.out`
    end

    if File.exists?('/tmp/top.out')
      counter = 0; proc_count = 0
      File.open("/tmp/top.out", "r") do |infile|
        while (line = infile.gets)
          processes(procs, line) if line.include?('Processes')
          load_averages(load_avg, line) if line.include?('Load Avg')
          cpu_usages(cpu_usage, line) if line.include?('CPU usage')
          proc_count = counter + 1 if line.include?('PID') and line.include?('COMMAND')
          process(processes, line) if proc_count > 0 and counter >= proc_count
          counter += 1
        end
      end
      
      options = {
        :body => {
          :heartbeat => {
            :apikey => apikey,
            :host => `hostname`.chomp,
            :timestamp => Time.now.to_i,
            :values => {
              :process_stats => procs,
              :load_avg => load_avg,
              :cpu_usage => cpu_usage,
              :processes => processes
            }
          }
        }
      }

      # puts procs.inspect
      # puts load_avg.inspect
      # puts cpu_usage.inspect
      # puts processes.inspect

      pp Heartbeat.post('/heartbeat', options)
    else
      put "No top output found."
    end
  end

  def self.processes(procs, str)
    proc = str.split(':')
    if proc and proc[0] and proc[0].include?('Processes')
      proc[1].split(',').each do |pr|
        procs['total'] = pr.split(' ')[0].strip.to_i if pr.include?('total')
        procs['running'] = pr.split(' ')[0].strip.to_i if pr.include?('running')
        procs['stuck'] = pr.split(' ')[0].strip.to_i if pr.include?('stuck')
        procs['sleeping'] = pr.split(' ')[0].strip.to_i if pr.include?('sleeping')
        procs['threads'] = pr.split(' ')[0].strip.to_i if pr.include?('threads')
      end
    end
  end

  def self.load_averages(load_avg, str)
    avg = str.split(':')
    if avg and avg[0] and avg[0].include?('Load Avg')
      avg[1].split(',').each do |a|
        load_avg << a.strip.to_f
      end
    end
  end

  def self.cpu_usages(cpu_usage, str)
    cpu = str.split(':')
    if cpu and cpu[0] and cpu[0].include?('CPU usage')
      cpu[1].split(',').each do |cp|
        cpu_usage['user'] = cp.split(' ')[0].strip.to_f if cp.include?('user')
        cpu_usage['sys'] = cp.split(' ')[0].strip.to_f if cp.include?('sys')
        cpu_usage['idle'] = cp.split(' ')[0].strip.to_f if cp.include?('idle')
      end
    end
  end

  def self.process(processes, line)
    procs = line.split(' ')
    if procs and procs.size > 0
      processes << {'pid' => procs[0].strip.to_i, 'command' => procs[1].strip, 'cpu' => procs[2].strip.to_f}
    end
  end
end
