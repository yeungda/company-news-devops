CONFIG_FILE = File.expand_path(File.dirname(__FILE__) + "/../../conf/mcollective.cfg")
LIB_DIR = "#{File.dirname(__FILE__)}/../vendor"
$: << LIB_DIR

require 'mcollective'

namespace :mc do
  include MCollective::RPC

  desc "pings all nodes"
  task :ping => :admin_server_address do
    discovery = mc_client 'discovery'
    puts "** pinging all nodes:".cyan
    discovery.ping.each do |node|
      print "* ".green
      puts node[:sender].white
    end
  end

  desc "deploys the application using mcollective"
  task :deploy, :environment, :war_file, :needs => :admin_server_address do |task, args|
    fail "you did not specify the environment to deploy to" if args[:environment].nil?

    war_file = args[:war_file] || go_artifact_uri
    fail "could not determine which war file to deploy" if war_file.nil?

    deploy = mc_client "deploy"
    deploy.fact_filter "environment=#{args[:environment]}"
    printrpc deploy.war(:source => war_file)
  end

  desc "prints an inventory report for the specified node"
  task :inventory, :node, :needs => :admin_server_address do |task, args|
    fail "no node specified".red if args[:node].nil?
    node = args[:node]

    util = mc_client("rpcutil")
    util.identity_filter node
    util.progress = false

    nodestats = util.custom_request("daemon_stats", {}, node, {"identity" => node})

    util.custom_request("inventory", {}, node, {"identity" => node}).each do |resp|
      puts "Inventory for #{resp[:sender]}:"
      puts

      if nodestats.is_a?(Array)
        nodestats = nodestats.first[:data]
        puts "   Server Statistics:"
        puts "                      Version: #{nodestats[:version]}"
        puts "                   Start Time: #{Time.at(nodestats[:starttime])}"
        puts "                  Config File: #{nodestats[:configfile]}"
        puts "                   Process ID: #{nodestats[:pid]}"
        puts "               Total Messages: #{nodestats[:total]}"
        puts "      Messages Passed Filters: #{nodestats[:passed]}"
        puts "            Messages Filtered: #{nodestats[:filtered]}"
        puts "                 Replies Sent: #{nodestats[:replies]}"
        puts "         Total Processor Time: #{nodestats[:times][:utime]} seconds"
        puts "                  System Time: #{nodestats[:times][:stime]} seconds"

        puts
      end

      puts "   Agents:"
      resp[:data][:agents].sort.in_groups_of(3, "") do |agents|
        puts "      %-15s %-15s %-15s" % agents
      end
      puts

      puts "   Configuration Management Classes:"
      resp[:data][:classes].sort.in_groups_of(2, "") do |klasses|
        puts "      %-30s %-30s" % klasses
      end
      puts

      puts "   Facts:"
      resp[:data][:facts].sort_by{|f| f[0]}.each do |f|
        puts "      #{f[0]} => #{f[1]}"
      end

      break
    end
  end

  task :admin_server_address do
    if ENV["STOMP_SERVER"]
      ENV["ADMIN_SERVER"] = ENV["STOMP_SERVER"]
    else
      Rake::Task["#{BUILD_DIR}/admin_server"].invoke
      ENV['STOMP_SERVER'] = ENV['ADMIN_SERVER'] = File.read("#{BUILD_DIR}/admin_server")
    end
  end

  #todo: look at nbn's go. can we refer to the artifact from the previous deploy stage as well?
  def go_artifact_uri
    server = ENV['ADMIN_SERVER']
    pipeline_counter = ENV['GO_PIPELINE_COUNTER']
    stage_counter = ENV['GO_STAGE_COUNTER']
    "http://#{server}:8153/go/files/MainBuild/#{pipeline_counter}/MainBuild/#{stage_counter}/MainBuild/dist/companyNews.war"
  end


  def mc_client(agent)
    rpcclient agent,
      :options => {
        :config      => CONFIG_FILE,
        :disctimeout => 5,
        :timeout     => 480,
        :verbose     => true,
        :collective  => 'mcollective',
        :filter      => ::MCollective::Util.empty_filter}
  end

  class Array
    def in_groups_of(chunk_size, padded_with=nil)
      arr = self.clone
      padding = chunk_size - (arr.size % chunk_size)
      arr.concat([padded_with] * padding)
      count = arr.size / chunk_size
      result = []
      count.times {|s| result <<  arr[s * chunk_size, chunk_size]}
      if block_given?
        result.each{|a| yield(a)}
      else
        result
      end
    end
  end
end

