#!/usr/bin/env ruby

module Utility
  DEFAULTS = {
    grafana: {
      image_version: '6.1.6',
      dockerhub_user: 'grafana',
      dockerhub_image: 'grafana'
    },
    prometheus: {
      image_version: 'v2.9.2',
      dockerhub_user: 'prom',
      dockerhub_image: 'prometheus',
      tsdb_retention: '2h'
    },
    node_exporter: {
      image_version: 'v0.18.0',
      dockerhub_user: 'prom',
      dockerhub_image: 'node-exporter'
    }
  }
  class OptionsObject
    require 'optparse'
    def initialize
      @options = {
        grafana: {},
        prometheus: {},
        node_exporter: {}
      }
      config
    end

    def config
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

        @options[:grafana][:image_version] = Utility::DEFAULTS[:grafana][:image_version]
          opts.on( '-g', '--grafana-version VERSION', 'Grafana version' ) do |grafana_ver|
          @options[:grafana][:image_version] = grafana_ver
        end

        @options[:prometheus][:image_version] = Utility::DEFAULTS[:prometheus][:image_version]
        opts.on( '-p', '--prometheus-version VERSION', 'Prometheus version' ) do |prometheus_ver|
          @options[:prometheus][:image_version] = prometheus_ver
        end

        @options[:node_exporter][:image_version] = Utility::DEFAULTS[:node_exporter][:image_version]
        opts.on( '-n', '--node-exporter-version VERSION', 'Node Exporter version' ) do |node_exporter_ver|
          @options[:node_exporter][:image_version] = node_exporter_ver
        end

        @options[:prometheus][:tsdb_retention] = Utility::DEFAULTS[:prometheus][:tsdb_retention]
        opts.on( '-r', '--tsdb-retention TIME', 'Prometheus TSDB retention' ) do |tsdb_retention|
          @options[:prometheus][:tsdb_retention] = tsdb_retention
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

  class LoggerObject
    require 'logger'
    def initialize
      @logger = Logger.new STDOUT
    end

    def info obj
      @logger.info obj
    end
  end

  class ExecutorObject

    def cli_flags
      Utility::OptionsObject.new.get_opts
    end

    def docker cmd
      DockerAPI::DockerInfo.new.send cmd 
    end

    def image image, cmd: nil
      img = DockerAPI::ImageObject.new image 
      img.send cmd if cmd
    end

    def images cmd
      DockerAPI::ImagesBulkObject.new.send cmd
    end

    def container settings, cmd: nil
      container = DockerAPI::ContainerObject.new settings
      container.send cmd if cmd 
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

  class ImageObject
    def initialize image_name
      @image = Docker::Image.create fromImage: image_name
    end

    def rmi
      @image.remove force: true
    end

    def describe
      @image.json
    end
  end

  class ImagesBulkObject
    def initialize
      @images = Docker::Image
    end

    def all
      @images.all
    end
  end

  class ContainerObject
    def initialize settings
      @container = Docker::Container.create settings
    end

    # def start name
    #   @container.start @name
    # end

    # def stop name
    #   @container.stop @name
    # end
  end
end

executor = Utility::ExecutorObject.new
logger = Utility::LoggerObject.new

existing_images = []
images = executor.images :all
images.each do |img|
  existing_images << img.info['RepoTags'].first
end

tags = executor.cli_flags
settings = Utility::DEFAULTS
settings.each do |k,v|
  image_definition = "#{v[:dockerhub_user]}/#{v[:dockerhub_image]}:#{tags[k][:image_version]}"
  unless existing_images.include? image_definition
    logger.info "Downloading #{k.capitalize} image version: #{tags[k][:image_version]} from dockerhub repo: #{v[:dockerhub_user]}/#{v[:dockerhub_image]}"
    executor.image image_definition
  end
  logger.info "Image #{image_definition} already exist. Skipping pull."
end

settings = {
  'name' => 'grafana-test-api',
  'Image' => "#{settings[:grafana][:dockerhub_user]}/#{settings[:grafana][:dockerhub_image]}:#{tags[:grafana][:image_version]}",
  'ExposedPorts' => { '3000/tcp' => {} },
  'HostConfig' => {
    'PortBindings' => {
      '3000/tcp' => [{ 'HostPort' => '3000' }]
    }
  }
}
executor.container settings


# %w(version info url).each do |cmd|
#   logger.info executor.docker cmd
# end