# Debezium Demo: MySQL -> PostgreSQL

This project builds a three node cluster:

* MySQL
* PostgreSQL
* Kafka

To begin, run `vagrant up`. The boxes are created and configured in order such that once they are all running, Debezium will have read all the data
 in MySQL, written it to Kafka and the JDBC sink will have written it to PostgreSQL. You can then connect to individual nodes and explore.

## MySQL

MySQL is installed with apt and a database named `sakila` is created with a user also named `sakila` having the imaginative password of `sakila`. The database is populated with the [Sakila](https://dev.mysql.com/doc/sakila/en/) sample database. Please note that binary logging is not switched on at this stage - this is to demonstrate that the initial load that Debezium performs is not dependant on the binary log. Once the data is loaded, binary logging is enabled as all future changes must be captured through the binary log.

## PostgreSQL

The PostgreSQL setup is very straighforward, simply another `sakila` database owned by a `sakila` user again with the password of `sakila`. We do not create a schema as we'll rely on the JDBC sink to do this for us.

## Kafka

This box will take a while to provison owing to the amount of Java dependencies that are fetched as part of compiling the Confluent open source tools. The long sequence of Bash scripts perform the following:

### `kafka-setup.sh`

* Install JDK with apt
* Download & configure Apache Kafka
* Write systemd service files for ZooKeeper and Kafka
* Start ZooKeeper & Kafka services

### `schema-registry-setup.sh`

* Download Maven
* Download & run Maven builds for Schema Registry and dependants
* Download & run Maven for Kafka Connect JDBC
* Write systemd service for Schema Registry and start the service

### `debezium-setup.sh`

* Download the Debezium releases and place in the filesystem
* Overwrite the default `connect-distributed.properties`
* Write systemd service file for Kafka Connect and start the service
* Configure the MySQL source through the Kafka Connect web service
* Configure the PostgreSQL sink through the Kafka Connect web service

The moment the MySQL source is configured, Debezium will connect to the database, read the schema and then fetch the data for each table and place it on the appropriate topics in Kafka. The log file `connect-distributed.out` is quite detailed and notes the time it takes for each stage to complete. Of particular interest is how long an exclusive lock on the database was required for the inital schema parse.

The PostgeSQL sink is for the single table `actor`. As soon as data is present, the schema will be taken from the Schema Registry, a table created in PostgreSQL and then loaded with the data. 
