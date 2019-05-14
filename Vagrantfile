# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
	config.vm.provider 'virtualbox' do |v|
		v.memory = 1024
		v.cpus = 2
	end
	# config.vm.network :forwarded_port, guest: 8001, host: 8001
	config.vm.provision :docker
	config.vm.provision :shell, path: 'install-rvm.sh', args: 'stable', privileged: false
	config.vm.provision :shell, path: 'install-ruby.sh', args: '2.6.3 docker-api', privileged: false
end
