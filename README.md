Prerequisites
------------
* MacOS
  - docker for Mac (Docker version 18.09.0, build 4d60db4)
  - ruby >= 2.5.0
  - [docker for mac](https://docs.docker.com/docker-for-mac/install/)
  - [bundler gem](https://bundler.io/)
* Windows
  - Docker version 18.09.0, build 4d60db4
  - [vagrant](https://www.vagrantup.com/) >= 2.1.5
  - [virtualbox](https://www.virtualbox.org/wiki/Downloads) >= 5.2.26

How to run
-----------
### MacOS

  - clone repo
    ```
    git clone https://github.com/nikitabugrovsky/docker-outbrain.git  && cd docker-outbrain
    ```
  - start executable
    ```
    ruby monitor.rb
    ```

### Windows

  - clone repo
    ```
    git clone https://github.com/nikitabugrovsky/docker-outbrain.git  && cd docker-outbrain
    ```
  - start executable
    ```
    vagrant up && vagrant ssh
    ```

Available Options
------------------
```bash
Usage: monitor.rb [options]
    -g, --grafana-version VERSION    Grafana version
    -p, --prometheus-version VERSION Prometheus version
    -n VERSION,                      Node Exporter version
        --node-exporter-version
    -r, --tsdb-retention TIME        Prometheus TSDB retention
    -h, --help                       Display all available options
```

Requirements
-------------
Please write a tool in the language of your choice that will take the following 4 parameters:
  - [x] Prometheus version
  - [x] Prometheus Retention in hours
  - [x] Grafana version.
  - [x] Node exporter version.
The script will spin up an monitoring environment which will include the following components:
  - [x] Prometheus server inside a container of the given prometheus version with the specified storage retention and with a job which will scrape it's own prometheus metrics together with node exporter metrics.
  - [x] Grafana container with given version which is connected to prometheus    server as a datasource and holds a predefined dashboards
    - [ ] a prometheus server dashboard with few prometheus metrics (please choose any metric you want).
    - [ ] a node exporter dashboard with few node exporter metrics.
  - [x] a container which runs a node exporter and exposing metrics to prom server.
  - [x] All components have to be a docker components.
  - [x] The tool have to be one executable file.
  - [x] Both Prometheus UI, Grafana and node exporter should be accessible from localhost browser.
  - [ ] Please make sure prometheus version 1.x.x and 2.x.x both work.

TODO
----

  - images/containers cleanup
  - proper logging
  - error handling
