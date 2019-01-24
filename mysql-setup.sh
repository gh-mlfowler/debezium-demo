#!/bin/bash -xe

apt-get -y update
apt-get -y install mysql-server

mysql -e "CREATE DATABASE sakila;"
mysql -e "CREATE USER sakila IDENTIFIED BY 'sakila';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO sakila;"
mysql -u sakila -psakila sakila < sakila-schema.sql
mysql -u sakila -psakila sakila < sakila-data.sql

echo "server-id        = 2019" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "log_bin          = /var/log/mysql/mysql-bin.log" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "binlog_format    = row" >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo "binlog_row_image = full" >> /etc/mysql/mysql.conf.d/mysqld.cnf

sed -i '/bind-address/c\bind-address = 0.0.0.0' /etc/mysql/mysql.conf.d/mysqld.cnf

service mysql restart
