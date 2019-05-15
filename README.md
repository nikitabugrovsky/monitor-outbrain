Requirements
------------
* MacOS
  - ruby >= 2.5.0
  - [docker for mac](https://docs.docker.com/docker-for-mac/install/)
  - [bundler gem](https://bundler.io/)
* Windows
  - [vagrant](https://www.vagrantup.com/) >= 2.1.5
  - [virtualbox](https://www.virtualbox.org/wiki/Downloads) >= 5.2.26

How to run
-----------
# MacOS

  - clone repo
    ```
    git clone https://github.com/nikitabugrovsky/docker-outbrain.git  && cd docker-outbrain
    ```
  - start executable
    ```
    ruby monitor.rb
    ```

# Windows

  - clone repo
    ```
    git clone https://github.com/nikitabugrovsky/docker-outbrain.git  && cd docker-outbrain
    ```
  - start executable
    ```
    vagrant up && vagrant ssh
    ```

