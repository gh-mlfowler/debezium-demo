#!/bin/bash -xe
DEBEZIUM_VERSION=0.8.3
DBZ_MONGO_URL=https://repo1.maven.org/maven2/io/debezium/debezium-connector-mongodb/$DEBEZIUM_VERSION.Final/debezium-connector-mongodb-$DEBEZIUM_VERSION.Final-plugin.tar.gz
DBZ_PSQL_URL=https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/$DEBEZIUM_VERSION.Final/debezium-connector-mysql-$DEBEZIUM_VERSION.Final-plugin.tar.gz
DBZ_MYSQL_URL=https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/$DEBEZIUM_VERSION.Final/debezium-connector-postgres-$DEBEZIUM_VERSION.Final-plugin.tar.gz

mkdir -p /opt/debezium

wget -q -O debezium.tar.gz $DBZ_MONGO_URL
tar -xzvf debezium.tar.gz -C /opt/debezium/

wget -q -O debezium.tar.gz $DBZ_PSQL_URL
tar -xzvf debezium.tar.gz -C /opt/debezium/

wget -q -O debezium.tar.gz $DBZ_MYSQL_URL
tar -xzvf debezium.tar.gz -C /opt/debezium/

chown -R kafka:kafka /opt/debezium

cp /opt/debezium/debezium-connector-postgres/postgresql-42.0.0.jar /opt/kafka/libs

cp connect-distributed.properties /opt/kafka/config
chown -R kafka:kafka /opt/kafka/config/connect-distributed.properties

# Creating systemd service for kafka connect
echo "[Unit]
Description=Kafka Connect Service
Documentation=http://kafka.apache.org
Requires=network.target
After=network.target

[Service]
Type=forking
User=kafka
Group=kafka
Environment=LOG_DIR='/opt/kafka/logs'
ExecStart=/opt/kafka/bin/connect-distributed.sh -daemon /opt/kafka/config/connect-distributed.properties

[Install]
WantedBy=default.target
" | tee /etc/systemd/system/kafka-connect.service

# Enabling the service
systemctl daemon-reload

service kafka-connect start

sleep 30

echo '{
  "name": "mysql-connector",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "192.168.100.8",
    "database.port": "3306",
    "database.user": "sakila",
    "database.password": "sakila",
    "database.server.id": "184054",
    "database.server.name": "mysql",
    "database.whitelist": "sakila",
    "database.history.kafka.bootstrap.servers": "127.0.0.1:9092",
    "database.history.kafka.topic": "dbhistory.sakila",
    "include.schema.changes": "true"
  }
}' | curl -X POST -d @- http://localhost:8083/connectors --header "Content-Type:application/json"

echo '{
    "name": "psql-sakila-sink-actor",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "topics": "mysql.sakila.actor",
      "connection.url": "jdbc:postgresql://192.168.100.9:5432/sakila?user=sakila&password=sakila",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.UnwrapFromEnvelope",
      "auto.create": "true",
      "insert.mode": "upsert",
      "table.name.format": "actor",
      "pk.fields": "actor_id",
      "pk.mode": "record_value"
    }
}' | curl -X POST -d @- http://localhost:8083/connectors --header "Content-Type:application/json"
