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
    procs = {'total' => 0, 'running' => 0, 'stuck' => 0, 'sleeping' => 0, 'threads' => 0, 'stopped' => 0, 'zombie' => 0}
    load_avg = []
    cpu_usage = {'user' => 0, 'sys' => 0, 'idle' => 0}
    processes = []

    if is_linux?
      `top -b -n1 > /tmp/top.out`
    else
      `top -l 1 > /tmp/top.out`
    end

    if File.exists?('/tmp/top.out')
      counter = 0; proc_count = 0
      File.open("/tmp/top.out", "r") do |infile|
        while (line = infile.gets)
          if is_linux?
            processes(procs, line) if line.include?('Task')
            load_averages(load_avg, line) if line.include?('load average')
            cpu_usages(cpu_usage, line) if line.include?('Cpu')
            proc_count = counter + 1 if line.include?('PID') and line.include?('COMMAND')
          else
            processes(procs, line) if line.include?('Processes')
            load_averages(load_avg, line) if line.include?('Load Avg')
            cpu_usages(cpu_usage, line) if line.include?('CPU usage')
            proc_count = counter + 1 if line.include?('PID') and line.include?('COMMAND')
          end
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

      #puts procs.inspect
      #puts load_avg.inspect
      #puts cpu_usage.inspect
      #puts processes.inspect

      Heartbeat.post('/heartbeat', options)
    else
      put "No top output found."
    end
  end

  def self.processes(procs, str)
    proc = str.split(':')
    if proc and proc[0]
      proc[1].split(',').each do |pr|
        procs['total'] = pr.split(' ')[0].strip.to_i if pr.include?('total')
        procs['running'] = pr.split(' ')[0].strip.to_i if pr.include?('running')
        procs['stuck'] = pr.split(' ')[0].strip.to_i if pr.include?('stuck')
        procs['sleeping'] = pr.split(' ')[0].strip.to_i if pr.include?('sleeping')
        procs['threads'] = pr.split(' ')[0].strip.to_i if pr.include?('threads')
        procs['stopped'] = pr.split(' ')[0].strip.to_i if pr.include?('stopped')
        procs['zombie'] = pr.split(' ')[0].strip.to_i if pr.include?('zombie')
      end
    end
  end

  def self.load_averages(load_avg, str)
    avg = str.split(is_linux? ? 'load average:' : ':')
    if avg and avg[0]
      avg[1].split(',').each do |a|
        load_avg << a.strip.to_f
      end
    end
  end

  def self.cpu_usages(cpu_usage, str)
    cpu = str.split(':')
    if cpu and cpu[0]
      cpu[1].split(',').each do |cp|
        cpu_usage['user'] = cp.split(' ')[0].strip.to_f if cp.include?(is_linux? ? 'us' : 'user')
        cpu_usage['sys'] = cp.split(' ')[0].strip.to_f if cp.include?(is_linux? ? 'sy' : 'sys')
        cpu_usage['idle'] = cp.split(' ')[0].strip.to_f if cp.include?(is_linux? ? 'id' : 'idle')
      end
    end
  end

  def self.process(processes, line)
    procs = line.split(' ')
    if procs and procs.size > 0
      processes << (is_linux? ? procs[11].strip : procs[1].strip)
    end
  end
end
