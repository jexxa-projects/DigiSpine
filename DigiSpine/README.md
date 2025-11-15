# Documentation of configuration decisions for the Digispine

## Kafka
TODO

## Schemaregistry
TODO

## Kafka-UI
Kafka-UI provides an interface for direct interaction with Kafka.
It is also able to provide an interface for the schemaregistry and ksqlDB, if they are registered.
The environment-properties "KAFKA_CLUSTERS_0_SCHEMAREGISTRY" and "KAFKA_CLUSTERS_0_KSQLDBSERVER" provide default configurations for the address of the schemaregistry and ksqlDB-Server, so that they are registered automatically.
In an SCS, the schemaregistry and ksqlDB-Server can be accessed with the following addresses respectively: "http://schemaregistry:8085", "http://ksqldbServer:8088".

TODO: document other decisions

## ksqlDB-Server
TODO

## ksqlDB-CLI
TODO

## Volumes
TODO


# Issues
Issues that may arise when creating a Digispine and possible solutions are documented here.

## Schemaregistry
### Topic Cleanup Policy
The Schemaregistry automatically creates a topic "_schemas" in Kafka in order to save the registered schemas.
Every Kafka-topic has the "cleanup.policy" property.
This property determines whether the messages on that topic are deleted after a certain amount of time (value: "delete") or whether the last value for each message-key is always retained (value: "compact").
The default setting for Kafka-topics is "delete", but the schemaregistry requires a "compact" cleanup policy for the topic "_schemas".

The current value can be viewed in Kafka-UI.

![CleanupPolicy](images/CleanupPolicy.png)

If this value is "delete", it can be changed as follows:

First, the console of a Kafka-container has to be opened in Portainer.
The following command displays the configuration of the topic "_schemas": \
/bin/kafka-configs --bootstrap-server http://kafka1:9092 --entity-type topics --entity-name _schemas --describe --all

After verifying that this is the right configuration, the cleanup policy of the topic "_schemas" can be changed to "compact" with the following command: \
/bin/kafka-configs --bootstrap-server http://kafka1:9092 --entity-type topics --entity-name _schemas --alter --add-config cleanup.policy=compact

If schemas have already been deleted by the cleanup policy, a restart of the respective producer should cause them to register in the schema registry again.
