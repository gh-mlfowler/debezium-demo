#!/bin/bash -xe

apt-get -y update
apt-get -y install postgresql-10

su -c 'psql -c "CREATE USER sakila WITH PASSWORD '"'sakila'"';"' postgres
su -c 'psql -c "CREATE DATABASE sakila OWNER sakila"' postgres

sed -i '/listen_addresses/c\listen_addresses = '"'*'"'' /etc/postgresql/10/main/postgresql.conf
echo "host  all all 192.168.100.0/24  md5" >> /etc/postgresql/10/main/pg_hba.conf
service postgresql restart
