# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/bionic64"

  config.vm.define "mysql" do |mysql|
    mysql.vm.network "private_network", ip: "192.168.100.8"
    mysql.vm.provision "file", source: "sakila-schema.sql", destination: "sakila-schema.sql"
    mysql.vm.provision "file", source: "sakila-data.sql", destination: "sakila-data.sql"
    mysql.vm.provision "shell", path: "mysql-setup.sh"
  end

  config.vm.define "psql" do |psql|
    psql.vm.network "private_network", ip: "192.168.100.9"
  end

  config.vm.define "kafka" do |kafka|
    kafka.vm.provider "virtualbox" do |v|
      v.memory = 4096
    end
    kafka.vm.network "private_network", ip: "192.168.100.10"
    kafka.vm.provision "file", source: "connect-distributed.properties", destination: "connect-distributed.properties"
    kafka.vm.provision "file", source: "kafka-setup.sh", destination: "kafka-setup.sh"
    kafka.vm.provision "file", source: "schema-registry-setup.sh", destination: "schema-registry-setup.sh"
    kafka.vm.provision "file", source: "debezium-setup.sh", destination: "debezium-setup.sh"
  end

end
