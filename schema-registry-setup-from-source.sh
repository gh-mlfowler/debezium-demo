#!/bin/bash -xe
MAVEN_VERSION="3.6.0"
CONFLUENT_VERSION="5.0.1"

MAVEN_URL="http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz"

COMMONS_URL="https://github.com/confluentinc/common/archive/v$CONFLUENT_VERSION.tar.gz"
REST_UTILS_URL="https://github.com/confluentinc/rest-utils/archive/v$CONFLUENT_VERSION.tar.gz"
SCHEMA_REG_URL="https://github.com/confluentinc/schema-registry/archive/v$CONFLUENT_VERSION.tar.gz"
CONNECT_JDBC_URL="https://github.com/confluentinc/kafka-connect-jdbc/archive/v$CONFLUENT_VERSION.tar.gz"

# Download Maven to build all these sources we download
wget -q -O maven.tar.gz $MAVEN_URL
tar -xzvf maven.tar.gz -C /opt/
ln -s /opt/apache-maven-$MAVEN_VERSION /opt/maven

#Pull down the sources, compile & install
wget -q -O commons.tar.gz $COMMONS_URL
tar -xzvf commons.tar.gz -C /opt/
(cd /opt/common-$CONFLUENT_VERSION && /opt/maven/bin/mvn -B -DskipTests install)

wget -q -O rest-utils.tar.gz $REST_UTILS_URL
tar -xzvf rest-utils.tar.gz -C /opt/
(cd /opt/rest-utils-$CONFLUENT_VERSION && /opt/maven/bin/mvn -B -DskipTests install)

wget -q -O connect-jdbc.tar.gz $CONNECT_JDBC_URL
tar -xzvf connect-jdbc.tar.gz -C /opt/
(cd /opt/kafka-connect-jdbc-$CONFLUENT_VERSION && /opt/maven/bin/mvn -B -DskipTests install)

wget -q -O schema-registry.tar.gz $SCHEMA_REG_URL
tar -xzvf schema-registry.tar.gz -C /opt/
ln -s /opt/schema-registry-$CONFLUENT_VERSION /opt/schema-registry
(cd /opt/schema-registry-$CONFLUENT_VERSION && /opt/maven/bin/mvn -B -DskipTests package)

mkdir -p /opt/schema-registry/share/java
cp -av /opt/schema-registry/package-kafka-serde-tools/target/kafka-serde-tools-package-$CONFLUENT_VERSION-development/share/java/kafka-serde-tools /opt/schema-registry/share/java
cp -av /opt/schema-registry/package-schema-registry/target/kafka-schema-registry-package-$CONFLUENT_VERSION-development/share/java/schema-registry /opt/schema-registry/share/java

mkdir -p /opt/schema-registry/share/java/kafka-connect-jdbc
cp -av /opt/kafka-connect-jdbc-$CONFLUENT_VERSION/target/kafka-connect-jdbc-$CONFLUENT_VERSION.jar /opt/schema-registry/share/java/kafka-connect-jdbc

chown -R kafka:kafka /opt/schema-registry /opt/schema-registry-$CONFLUENT_VERSION

# Creating systemd service for schema registry
echo "[Unit]
Description=Kafka Schema Registry Service
Documentation=https://docs.confluent.io/current/schema-registry/docs/index.html
Requires=kafka.service
After=kafka.service

[Service]
Type=simple
User=kafka
Group=kafka
Environment=LOG_DIR='/opt/kafka/logs'
ExecStart=/opt/schema-registry/bin/schema-registry-start /opt/schema-registry/config/schema-registry.properties
ExecStop=/opt/schema-registry/bin/schema-registry-stop

[Install]
WantedBy=default.target
" | tee /etc/systemd/system/kafka-schema.service

# Enabling the service
systemctl daemon-reload

service kafka-schema start
