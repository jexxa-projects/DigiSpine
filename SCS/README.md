# TODO

## ksqlDB example

```sql
CREATE STREAM s1 
WITH (kafka_topic='example-topic2', value_format='avro');
```

```sql
CREATE STREAM s2 AS
SELECT * FROM s1
WHERE wertInCelsius > 1200 EMIT CHANGES;
```
