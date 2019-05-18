Prerequisites
------------
* MacOS
  - ruby >= 2.5.0
  - [docker for mac](https://docs.docker.com/docker-for-mac/install/) (Docker version 18.09.0, build 4d60db4)
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
    bundle && ruby monitor.rb
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
    - [x] a prometheus server dashboard with few prometheus metrics (please choose any metric you want).
    - [x] a node exporter dashboard with few node exporter metrics.
  - [x] a container which runs a node exporter and exposing metrics to prom server.
  - [x] All components have to be a docker components.
  - [x] The tool have to be one executable file.
  - [x] Both Prometheus UI, Grafana and node exporter should be accessible from localhost browser.
  - [x] Please make sure prometheus version 1.x.x and 2.x.x both work.

Versions Tested
----------------

| Prometheus  | Grafana  | Node Exporter |
|-------------|----------|---------------|
|   2.9.2     |  6.1.6   |    0.18.0     |
|   2.8.1     |  5.4.4   |    0.17.0     |
|   1.6.3     |  5.1.0   |    0.15.1     |

Next Steps
----------

  - images/containers cleanup
  - proper logging
  - error handling
  - move data hashes to db (mongo/elasticsearch)
  - build templating engine

Caveats
--------
 - Unfortunately grafana api gem is out of date & opinionated. Dashboard generation is broken. I used excon gem to sort things out.
 - Please do not open different versions of grafana in the same browser tab. Browser cache might break grafana dashboards. Use incognito mode instead. 
