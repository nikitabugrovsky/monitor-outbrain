#!/usr/bin/env ruby

module FlowControl
  class OptionsObject

    require 'optparse'

    def initialize
      @options = {}
      config
    end

    def config

      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

        @options[:grafana_ver] = nil
        opts.on( '-g', '--grafana-version VERSION', 'Grafana version' ) do |grafana_ver|
        @options[:grafana_ver] = grafana_ver
        end

        @options[:prometheus_ver] = nil
        opts.on( '-p', '--prometheus-version VERSION', 'Prometheus version' ) do |prometheus_ver|
          @options[:prometheus_ver] = prometheus_ver
        end

        @options[:tsdb_retention] = nil
        opts.on( '-r', '--tsdb-retention TIME', 'Prometheus TSDB retention' ) do |tsdb_retention|
          @options[:tsdb_retention] = tsdb_retention
        end

        opts.on( '-h', '--help', 'Display all available options' ) do
          puts opts
          exit
        end
      end
      optparse.parse!
    end

    def get_opts
      @options
    end
  end

  class LauncherObject
    def cli_flags
      FlowControl::OptionsObject.new.get_opts
    end

    def docker_describe(cmd)
      DockerAPI::DockerInfo.new.send(cmd)
    end
  end
end

module DockerAPI
  require 'docker'
  class DockerInfo
    def version
      Docker.version
    end

    def info
      Docker.info
    end

    def url
      Docker.url
    end
  end
end

launcher = FlowControl::LauncherObject.new
puts launcher.cli_flags
%w(version info url).each do |cmd|
  puts launcher.docker_describe(cmd)
end
