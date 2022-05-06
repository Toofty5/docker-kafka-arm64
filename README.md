Kafka in Docker in arm64  (Fork Notes)
===
Forked from Spotify's dockerfile and modified to work with arm64 architecture for use on Raspberry Pi, with guidance from [Ligato](https://docs.ligato.io/en/dev/user-guide/arm64/)

It seems the JRE base image at java:openjdk-8-jre has no ARM64 build, so Ligato changed it for openjdk:8-jre, which works.  However, the Spotify image also fails because the download mirror for the Kafka install is no longer valid, so I have abstracted that to the DOWNLOAD_URL variable in the Dockerfile and updated it to https://dlcdn.apache.org/kafka.  I have also updated the Kafka and Scala version numbers to newer versions.

Lastly, I have added the ADVERTISED_LISTENER variable to receive requests inside the container.  Setting this to the same as ADVERTISED_HOST seems to work for me, but until I learn some more about exactly how/why this works, I'm leaving it as separate variables rather than combining them.

To install kafka-arm64
---
```bash
docker pull toofty5/kafka-arm64:latest
```

To run kafka-arm64
---
```bash
docker run -p 2181:2181 -p 9092:9092 --env ADVERTISED_LISTENER=`docker-machine ip \`docker-machine active\`` --env ADVERTISED_HOST=`docker-machine ip \`docker-machine active\`` --env ADVERTISED_PORT=9092 toofty5/kafka-arm64
```




Kafka in Docker (Original readme from Spotify)
===

This repository provides everything you need to run Kafka in Docker.

For convenience also contains a packaged proxy that can be used to get data from
a legacy Kafka 7 cluster into a dockerized Kafka 8.

Why?
---
The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container
* Zookeeper and Kafka are configured to work together out of the box

Run
---

```bash
docker run -p 2181:2181 -p 9092:9092 --env ADVERTISED_HOST=`docker-machine ip \`docker-machine active\`` --env ADVERTISED_PORT=9092 spotify/kafka
```

```bash
export KAFKA=`docker-machine ip \`docker-machine active\``:9092
kafka-console-producer.sh --broker-list $KAFKA --topic test
```

```bash
export ZOOKEEPER=`docker-machine ip \`docker-machine active\``:2181
kafka-console-consumer.sh --zookeeper $ZOOKEEPER --topic test
```

Running the proxy
-----------------

Take the same parameters as the spotify/kafka image with some new ones:
 * `CONSUMER_THREADS` - the number of threads to consume the source kafka 7 with
 * `TOPICS` - whitelist of topics to mirror
 * `ZK_CONNECT` - the zookeeper connect string of the source kafka 7
 * `GROUP_ID` - the group.id to use when consuming from kafka 7

```bash
docker run -p 2181:2181 -p 9092:9092 \
    --env ADVERTISED_HOST=`boot2docker ip` \
    --env ADVERTISED_PORT=9092 \
    --env CONSUMER_THREADS=1 \
    --env TOPICS=my-topic,some-other-topic \
    --env ZK_CONNECT=kafka7zookeeper:2181/root/path \
    --env GROUP_ID=mymirror \
    spotify/kafkaproxy
```

In the box
---
* **spotify/kafka**

  The docker image with both Kafka and Zookeeper. Built from the `kafka`
  directory.

* **spotify/kafkaproxy**

  The docker image with Kafka, Zookeeper and a Kafka 7 proxy that can be
  configured with a set of topics to mirror.

Public Builds
---

https://registry.hub.docker.com/u/spotify/kafka/

https://registry.hub.docker.com/u/spotify/kafkaproxy/

Build from Source
---

    docker build -t spotify/kafka kafka/
    docker build -t spotify/kafkaproxy kafkaproxy/

Todo
---

* Not particularily optimzed for startup time.
* Better docs

