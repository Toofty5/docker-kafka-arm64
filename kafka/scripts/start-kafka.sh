#!/bin/sh

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic
# * CLUSTER_ID: generate with kafka-storage.sh random-uuid

# Configure advertised host/port if we run in helios
# Branch note: Helios is for media streaming -- probably more important for Spotify
# if [ ! -z "$HELIOS_PORT_kafka" ]; then
#     ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
#     ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
# fi
# 

# Set the external host and port (Deprecated for 3.0.1)
# if [ ! -z "$ADVERTISED_HOST" ]; then
#     echo "advertised host: $ADVERTISED_HOST"
#     if grep -q "^advertised.host.name" $KAFKA_HOME/config/server.properties; then
#         sed -r -i "s/#(advertised.host.name)=(.*)/\1=$ADVERTISED_HOST/g" $KAFKA_HOME/config/server.properties
#     else
#         echo "advertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
#     fi
# fi
# 
KRAFT_CONFIG_FILE="$KAFKA_HOME/config/kraft/server.properties"



if [ ! -z "$ADVERTISED_LISTENERS" ]; then
  echo "advertised listeners: $ADVERTISED_LISTENERS"
  sed -r -i "s@(advertised.listeners)=(.*)@advertised.listeners=PLAINTEXT://$ADVERTISED_LISTENERS@g" $KRAFT_CONFIG_FILE
fi

if [ ! -z "$NODE_ID" ]; then
  sed -r -i "s/(node.id)=(.*)/\1=$NODE_ID/g" $KRAFT_CONFIG_FILE
  sed -r -i "s/(controller.quorum.voters)=(.*)/\1=$NODE_ID@$ADVERTISED_LISTENERS:9093/g" $KRAFT_CONFIG_FILE
fi

echo "node ID: $NODE_ID"

# Allow specification of log retention policies
if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" $KRAFT_CONFIG_FILE
fi
if [ ! -z "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    sed -r -i "s/#(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" $KRAFT_CONFIG_FILE
fi

# Configure the default number of log partitions per topic
if [ ! -z "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" $KRAFT_CONFIG_FILE
fi

# Enable/disable auto creation of topics
if [ ! -z "$AUTO_CREATE_TOPICS" ]; then
    echo "auto.create.topics.enable: $AUTO_CREATE_TOPICS"
    echo "auto.create.topics.enable=$AUTO_CREATE_TOPICS" >> $KRAFT_CONFIG_FILE
fi

# If CLUSTER_ID is not defined then make one.  Afterwards, format the storage directories
if [ -z "$CLUSTER_ID" ]; then
  CLUSTER_ID=$($KAFKA_HOME/bin/kafka-storage.sh random-uuid)
fi

echo "cluster ID: $CLUSTER_ID"

$KAFKA_HOME/bin/kafka-storage.sh format -t $CLUSTER_ID -c $KRAFT_CONFIG_FILE

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KRAFT_CONFIG_FILE
