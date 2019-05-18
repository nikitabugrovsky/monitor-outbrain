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
          p @options
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

        def container definition: nil, cmd: nil
          container = DockerAPI::ContainerObject.new definition if definition
          container.send cmd if cmd
        end

        def network(cmd, *args)
          net = DockerAPI::NetworkObject.new
          net.send(cmd, *args) if cmd
        end

        def datasource(cmd, *args)
          ds = GrafanaAPI::Datasource.new
          ds.send(cmd, *args) if cmd
        end

        def dashboard(cmd, *args)
          dash = GrafanaAPI::Dashboard.new
          dash.send(cmd, *args) if cmd
        end
      end

      class ConfigGeneratorObject
        require 'yaml'

        def initialize file_name, file_ext
          @logger = Utility::LoggerObject.new
          config_to_file file_name, file_ext
        end

        def global interval: '15s', timeout: '10s', eval_int: '15s' 
          {
            'scrape_interval' => interval,
            'scrape_timeout' => timeout,
            'evaluation_interval' => eval_int
          }
        end

        def alerting scheme: 'http', timeout: '10s'
          { 
            'alertmanagers' => [
              { 
                'static_configs' => [
                  {
                    'targets' => []
                  }
                ],
                'scheme' => scheme,
                'timeout' => timeout
              }
            ]
          }
        end

        def scrape_config name, target_port 
          {
            'job_name' => name,
            'metrics_path' => '/metrics',
            'static_configs' => [
              {
                'targets' => [
                  "#{name}:#{target_port}"
                ]
              }
            ]
          }
        end

        def prometheus_config 
          {
            'global' => global,
            'alerting' => alerting,
            'scrape_configs' => [
              scrape_config('prometheus', 9090),
              scrape_config('node_exporter', 9100)
            ]
          }
        end

        def config_to_yaml
          prometheus_config.to_yaml
        end

        def config_to_file file_name, file_ext
          @logger.info "Writing custom configuration for prometheus to file #{Dir.pwd}/#{file_name}.#{file_ext}"
          File.open("#{Dir.pwd}/#{file_name}.#{file_ext}", 'w') { |file| file.write(config_to_yaml) }
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
        def initialize definition
          @container = Docker::Container.create definition
        end

        def start
          @container.start
        end

        def stop
          Docker::Container.get(@container.id).stop
        end

        def delete 
          Docker::Container.get(@container.id).delete force: true 
        end

        def describe
          Docker::Container.get(@container.id).json
        end

        def get 
          Docker::Container.get(@container.id)
        end
      end

      class NetworkObject
        def initialize
          @net = Docker::Network
        end

        def create name
          @net.create name
        end

        def get name
          Docker::Network.get(name)
        end

        def delete id
          Docker::Network.get(id).delete
        end

        def connect id, container
          Docker::Network.get(id).connect container
        end
      end
    end


    module GrafanaAPI
      require 'grafana'

      CONNECTION = {
        host: 'localhost',
        port: 3000,
        user: 'admin',
        pass: 'admin'
      }

      class Datasource
        def initialize
          conn = GrafanaAPI::CONNECTION
          @grafana = Grafana::Client.new(conn[:host], conn[:port], conn[:user], conn[:pass])
        end

        def list
          @grafana.get_data_sources()
        end

        def datasource_template name
          {
            "orgId"=>1, 
            "name"=>"#{name.capitalize}", 
            "type"=>"#{name}", 
            "typeLogoUrl"=>"public/app/plugins/datasource/prometheus/img/prometheus_logo.svg", 
            "access"=>"proxy", 
            "url"=>"http://#{name}:9090", 
            "password"=>"", 
            "user"=>"", 
            "database"=>"", 
            "basicAuth"=>false, 
            "isDefault"=>true, 
            "jsonData"=>{
              "httpMethod"=>"GET", 
              "keepCookies"=>[]
            },
            "readOnly"=>false
          }
        end

        def add_datasource name
          tmpl = datasource_template name
          @grafana.create_data_source(tmpl)
        end
      end

      class Dashboard
        require 'excon'
        def initialize
          conn = GrafanaAPI::CONNECTION
          api_endpoint = 'api/dashboards/db'
          @grafana = Excon.new("http://#{conn[:host]}:#{conn[:port]}/#{api_endpoint}", user: conn[:user], password: conn[:pass], headers: { "Content-Type" => "application/json" })
        end

        def dashboard_template name
          File.read "#{name}.json"
        end

        def create_dash name
          json_tmpl = dashboard_template name
          @grafana.request(method: 'POST', body: json_tmpl)
        end
      end
    end

    module FlowControl

      PORT_BINDINGS = {
        prometheus: '9090',
        grafana: '3000',
        node_exporter: '9100'
      }

      class NetworkController
        def initialize name
          executor = Utility::ExecutorObject.new
          logger = Utility::LoggerObject.new
          logger.info "Creating docker network: #{name}"
          logger.info executor.network :create, name
        end
      end

      class ImagesController
        def initialize options
          @executor = Utility::ExecutorObject.new
          @logger = Utility::LoggerObject.new
          @options = options
          @existing_images = []
          collect_images
          create_images
        end

        def collect_images
          images = @executor.images :all
          images.each do |img|
            @existing_images << img.info['RepoTags'].first
          end
        end

        def settings
          Utility::DEFAULTS
        end

        def create_images
          settings.each do |k,v|
            image_definition = "#{v[:dockerhub_user]}/#{v[:dockerhub_image]}:#{@options[k][:image_version]}"
            unless @existing_images.include? image_definition
              @logger.info "Downloading #{k.capitalize} image version: #{@options[k][:image_version]} from dockerhub repo: #{v[:dockerhub_user]}/#{v[:dockerhub_image]}"
              @executor.image image_definition
            end
            @logger.info "Image #{image_definition} already exist. Skipping pull." if @existing_images.include? image_definition
          end
        end
      end

      class ContainersController
        def initialize options
          @executor = Utility::ExecutorObject.new
          @logger = Utility::LoggerObject.new
          @options = options
          deploy_containers
        end

        def settings
          Utility::DEFAULTS
        end

        def prometheus_cmd
          cmd = []
          prometheus_version = @options[:prometheus][:image_version]
          if prometheus_version.chars[1] == "2"
            cmd << "--config.file=/etc/prometheus/prometheus.yml"
            cmd << "--storage.tsdb.path=/prometheus"
            cmd << "--web.console.libraries=/usr/share/prometheus/console_libraries"
            cmd << "--web.console.templates=/usr/share/prometheus/consoles"
            cmd << "--storage.tsdb.retention.time=#{@options[:prometheus][:tsdb_retention]}"
          elsif prometheus_version.chars[1] == "1"
            cmd << "-config.file=/etc/prometheus/prometheus.yml"
            cmd << "-storage.local.path=/prometheus"
            cmd << "-web.console.libraries=/usr/share/prometheus/console_libraries"
            cmd << "-web.console.templates=/usr/share/prometheus/consoles"
            cmd << "-storage.local.retention=2h"
          end
          cmd
        end

        def container_template name: nil, port: nil, cmd: nil, bind: nil
          image = "#{settings[name.to_sym][:dockerhub_user]}/#{settings[name.to_sym][:dockerhub_image]}:#{@options[name.to_sym][:image_version]}"
          tmpl = {
            name: name,
            Image: image,
            ExposedPorts: { "#{port}/tcp" => {} },
            HostConfig: {
              PortBindings: {
                "#{port}/tcp" => [{ 'HostPort' => port.to_s }]
              }
            }
          }
          tmpl[:Cmd] = cmd if cmd
          tmpl[:HostConfig][:Binds] = [ bind ] if bind
          tmpl
        end

        def deploy_containers
          PORT_BINDINGS.each do |container, port|
            image = "#{settings[container.to_sym][:dockerhub_user]}/#{settings[container.to_sym][:dockerhub_image]}:#{@options[container.to_sym][:image_version]}"
            @logger.info "Launching container #{container} from image #{image}"
            definition =  if container == :prometheus
                            bind_mount = "#{Dir.pwd}/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
                            container_template name: container, port: port, cmd: prometheus_cmd, bind: bind_mount                     
                          else
                            container_template name: container, port: port, cmd: nil, bind: nil
                          end
            @logger.info "#{container}: #{definition}"
            cnt = @executor.container definition: definition, cmd: :start
            sleep 3
            net = @executor.network :get, 'prometheus'
            @executor.network :connect, net.id, cnt.id
          end
        end
      end

      class GrafanaController
        def initialize
          @executor = Utility::ExecutorObject.new
          @logger = Utility::LoggerObject.new
        end

        def datasource_list
          @logger.info @executor.datasource :list
        end

        def add_datasource name
          added = @executor.datasource :add_datasource, name
          @logger.info "Adding datasource #{name} to Grafana Container" if added
        end

        def dashboard_list
          @logger.info @executor.dashboard :list
        end

        def create_dash name
          added = @executor.dashboard :create_dash, name 
          @logger.info "Adding dashboard to Grafana Container" if added
          @logger.info added
        end
      end
    end

  options = Utility::OptionsObject.new.get_opts
  Utility::ConfigGeneratorObject.new('prometheus', 'yml')
  FlowControl::NetworkController.new ('prometheus')
  FlowControl::ImagesController.new(options)
  FlowControl::ContainersController.new(options)
  grafana = FlowControl::GrafanaController.new
  grafana.add_datasource('prometheus')
  grafana.create_dash('prometheus_stats')
  grafana.create_dash('node_exporter_stats')
