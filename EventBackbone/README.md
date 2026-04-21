# Documentation of Configuration Decisions for Digispine

## Kafka
The system utilizes **Confluent Kafka images** configured for production readiness. Key optimizations include tuned replication factors and persistence settings to ensure high availability and data integrity across the cluster.

## Schema Registry
We use the **Confluent Schema Registry** to manage data schemas. Integration with **jlegmed** allows for the automatic registration of schemas via Jackson, ensuring seamless evolution of data structures without manual intervention.

## Kafka-UI
Kafka-UI provides a web-based interface for direct interaction with the cluster, Schema Registry, and ksqlDB.

- **Automatic Registration:** The environment properties `KAFKA_CLUSTERS_0_SCHEMAREGISTRY` and `KAFKA_CLUSTERS_0_KSQLDBSERVER` are pre-configured to link these services automatically.
- **SCS Access:** Within the Self-Contained System (SCS) network, the services are accessible via the following addresses:
    - **Schema Registry:** `http://schemaregistry:8085`
    - **ksqlDB Server:** `http://ksqldbServer:8088`

## Volumes
To minimize latency and maximize throughput, Kafka brokers are configured to use **SSD direct access**. This ensures that high-frequency disk I/O operations do not become a bottleneck for the message log.

---

# Troubleshooting & Issues

## Schema Registry: Topic Cleanup Policy
The Schema Registry automatically creates an internal Kafka topic named `_schemas` to store registered schemas.

### The Problem
Every Kafka topic has a `cleanup.policy` property:
- **delete**: Messages are deleted after a certain time (default for most topics).
- **compact**: Only the latest value for each message key is retained.

The Schema Registry **requires** the `compact` policy for the `_schemas` topic. If it is set to `delete`, schema data may be lost over time, causing the registry to fail.

### How to Fix
1. **Verify:** Check the current policy in the Kafka-UI under the topic settings for `_schemas`.
2. **Check Configuration:** Open a console for a Kafka container (e.g., via Portainer) and run the following command to see the current state:
   ```bash
   /bin/kafka-configs --bootstrap-server kafka1:9092 --entity-type topics --entity-name _schemas --describe --all
