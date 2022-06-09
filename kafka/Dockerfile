# Kafka and Zookeeper

FROM openjdk:8-jre

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.13
ENV KAFKA_VERSION 3.1.0
ENV DOWNLOAD_URL https://dlcdn.apache.org/kafka
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"

# Install Kafka and other needed things
RUN apt-get update && \
    apt-get install -y wget supervisor dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q "$DOWNLOAD_URL"/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    cp "$KAFKA_HOME"/config/kraft/server.properties /config && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

COPY scripts/start-kafka.sh /usr/bin/start-kafka.sh

# Supervisor config
COPY supervisor/kafka.conf /etc/supervisor/conf.d/

# 9092 for broker, 9093 for kraft controller
EXPOSE 9092 9093

CMD ["supervisord", "-n"]
