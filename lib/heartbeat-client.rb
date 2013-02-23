require 'rubygems'
gem 'httparty'
require 'httparty'
require 'logger'
require 'macaddr'
require 'net/http'
require 'json'
require 'keen'

class Heartbeat
  include HTTParty

  def self.is_mac?
    RUBY_PLATFORM.downcase.include?("darwin")
  end

  def self.is_linux?
    RUBY_PLATFORM.downcase.include?("linux")
  end
  
  def self.log=(logger)
    @@log = logger
  end

  def self.log
    @@log
  end

  def self.create(config, version = '0.0', gather_metrics = false)
    log.info("#create - Collecting data...")
    
    apikey = config['apikey']
    endpoint = config['endpoint']
    name = config['name']
    apache_status = config['apache_status']
    mongostat_arguments = config['mongostat_arguments']
    keen_project_token = config['keen_project_token']
    keen_api_key = config['keen_api_key']
    keen_collection = config['keen_collection']

    if gather_metrics
      procs = {'total' => 0, 'running' => 0, 'stuck' => 0, 'sleeping' => 0, 'threads' => 0, 'stopped' => 0, 'zombie' => 0}
      load_avg = []
      cpu_usage = {'user' => 0, 'sys' => 0, 'idle' => 0}
      processes = []
      memory = {'free' => 0, 'used' => 0}
      disks = {}
      swap = {'free' => 0, 'used' => 0}
      apache = {}
      mongodb = {}

      log.debug("Dumping top output...")
      if is_linux?
        `top -b -n1 > /tmp/top.out`
      else
        `top -l 1 > /tmp/top.out`
      end

      log.debug("Dumping df output...")
      `df -m > /tmp/dfm.out`

      if apache_status
        log.debug("Dumping apache status output...")
        `curl #{apache_status} > /tmp/apache.out`  
      end

      if mongostat_arguments
        log.debug("Dumping mongostat output...")
        `mongostat #{mongostat_arguments} > /tmp/mongodb.out`
      end

      if File.exists?('/tmp/top.out')
        counter = 0; proc_count = 0
        File.open("/tmp/top.out", "r") do |infile|
          while (line = infile.gets)
            if is_linux?
              processes(procs, line) if line.include?('Task')
              load_averages(load_avg, line) if line.include?('load average')
              cpu_usages(cpu_usage, line) if line.include?('Cpu')
              memory_usage(memory, line) if line.include?('Mem')
              swap_usage(swap, line) if line.include?('Swap')
              proc_count = counter + 1 if line.include?('PID') and line.include?('COMMAND')
            else
              processes(procs, line) if line.include?('Processes')
              load_averages(load_avg, line) if line.include?('Load Avg')
              cpu_usages(cpu_usage, line) if line.include?('CPU usage')
              memory_usage(memory, line) if line.include?('PhysMem')
              proc_count = counter + 1 if line.include?('PID') and line.include?('COMMAND')
            end
            process(processes, line) if proc_count > 0 and counter >= proc_count
            counter += 1
          end
        end

        if File.exists?('/tmp/dfm.out')
          File.open("/tmp/dfm.out", "r") do |infile|
            counter = 0
            while (line = infile.gets)
              disk_usage(disks, line) if counter > 0
              counter += 1
            end
          end
        end

        if File.exists?('/tmp/apache.out')
          File.open("/tmp/apache.out", "r") do |infile|
            counter = 0; lines = []
            while (line = infile.gets)
              apache_status(apache, line)
              counter += 1
            end
          end
        end

        if File.exists?('/tmp/mongodb.out')
          File.open("/tmp/mongodb.out", "r") do |infile|
            counter = 0; lines = []
            while (line = infile.gets)
              lines << line
            end
            mongodb_status(mongodb, lines)
          end
        end

        options = {
          :body => {
            :heartbeat => {
              :client_version => version,
              :apikey => apikey,
              :host => `hostname`.chomp,
              :macaddr => Mac.addr,
              :name => name,
              :timestamp => Time.now.to_i,
              :values => {
                :process_stats => procs,
                :load_avg => load_avg,
                :cpu_usage => cpu_usage,
                :processes => processes,
                :memory => memory,
                :disks => disks,
                :swap => swap,
                :apache_status => apache,
                :mongodb_status => mongodb
              }
            }
          }
        }

        log.info("#create - Sending data to endpoint (with metrics)...")
        res = Heartbeat.post(endpoint + '/heartbeat', options)
        log.debug("Response: #{res.response.inspect}") if res

        if keen_project_token and keen_api_key and keen_collection
          keen = Keen::Client.new(:project_id => keen_project_token, :api_key => keen_api_key)
          data = options[:body][:heartbeat]
          keen.publish(keen_collection, {:host => data[:host], :cpu => data[:values][:cpu_usage]})
        end
      else
        log.error "No top output found."
      end
    else
      options = {
        :body => {
          :heartbeat => {
            :client_version => version,
            :apikey => apikey,
            :host => `hostname`.chomp,
            :macaddr => Mac.addr,
            :name => name,
            :timestamp => Time.now.to_i
          }
        }
      }

      log.info("#create - Sending data to endpoint (no metrics)...")
      res = Heartbeat.post(endpoint + '/heartbeat', options)
      log.debug("Response: #{res.response.inspect}") if res
    end
    log.info("Finished iteration.")
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

  def self.process(processes, str)
    procs = str.split(' ')
    if procs and procs.size > 0
      processes << (is_linux? ? procs[11].strip : procs[1].strip)
    end
  end
  
  def self.memory_usage(memory, str)
    mem = str.split(':')
    if mem and mem[0]
      mem[1].split(',').each do |m|
        memory['free'] = m.split(' ')[0].strip if m.include?('free')
        memory['used'] = m.split(' ')[0].strip if m.include?('used')
      end
    end
  end

  def self.swap_usage(swap, str)
    sw = str.split(':')
    if sw and sw[0]
      sw[1].split(',').each do |s|
        swap['free'] = s.split(' ')[0].strip if s.include?('free')
        swap['used'] = s.split(' ')[0].strip if s.include?('used')
      end
    end
  end

  def self.apache_status(apache, str)
    ap = str.split(':')
    if ap and ap[0]
      apache['requests'] = ap[1].strip.to_f if ap[0].include?('ReqPerSec')
      apache['busy_workers'] = ap[1].strip.to_i if ap[0].include?('BusyWorkers')
      apache['idle_workers'] = ap[1].strip.to_i if ap[0].include?('IdleWorkers')
    end
  end

  def self.mongodb_status(mongodb, lines)
    if lines and lines.size == 3
      header = lines[1].gsub('%', '').gsub('miss', '').split(' '); mo = lines[2].split(' ')
      if header and mo and header.size == mo.size
        header.each_with_index do |h, index|
          mongodb['insert'] = mo[index].strip.to_i if h == 'insert'
          mongodb['query'] = mo[index].to_i if h == 'query'
          mongodb['update'] = mo[index].strip.to_i if h == 'update'
          mongodb['delete'] = mo[index].strip.to_i if h == 'delete'
          mongodb['getmore'] = mo[index].strip.to_i if h == 'getmore'
          mongodb['command'] = mo[index].strip.to_i if h == 'command'
          mongodb['flushes'] = mo[index].strip.to_i if h == 'flushes'
          mongodb['mapped'] = mo[index].strip if h == 'mapped'
          mongodb['vsize'] = mo[index].strip if h == 'vsize'
          mongodb['res'] = mo[index].strip if h == 'res'
          mongodb['netIn'] = mo[index].strip if h == 'netIn'
          mongodb['netOut'] = mo[index].strip if h == 'netOut'
          mongodb['conn'] = mo[index].strip if h == 'conn'
        end
      end
    end
  end

  def self.disk_usage(disks, str)
    ds = str.split(' ')
    disks[ds[0].strip] = {'used' => ds[2].strip, 'available' => ds[3].strip}
  end
end
