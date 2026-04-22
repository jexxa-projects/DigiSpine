# How to connect a Data Product to DigiSpine

IMPORTANT: WORK IN PROGRESS

## Goal 
- Prototype to demonstrate how to connect a streaming database to DigiSpine

## Used Technology 
- Used technology for data product: RisingWave(https://docs.risingwave.com/docs/current/intro/)
- Reasoning: 
  - Streaming database to allow stream processing
  - Native Kafka connector included in official docker image
  - postgres compatible 
  - Zookeeper is not required 
  - Open source 

## Setup 
- Deploy DigiSpine [digispine-compose-production.yml](../DigiSpine/digispine.yml) 
- Deploy [kconnect-console-producer.yml](../DigiSpine/kafka-connect-clients/kconnect-console-producer.yml)
- Deploy [dataproduct.yml](dataproduct.yml) (NOT PRODUCTION READY!!!)
- Docu: https://docs.risingwave.com/docs/current/get-started/

### Validate RisingWave installation
- Use some postgres-compatible client (dbvisualizer)

- Connection information: 
  - \<IP of docker with deployed dataproduct.yml\>:4566 
  - database: `dev`
  - User: `root`
  - PW: not required

- create a table (postgres like) 
    ```sql
    CREATE TABLE website_visits (
    timestamp timestamp with time zone,
    user_id varchar,
    page_id varchar,
    action varchar
    );
    ``` 
- insert data (postgres like)
    ```sql
    INSERT INTO website_visits (timestamp, user_id, page_id, action) VALUES
    ('2023-06-13T10:00:00Z', 'user1', 'page1', 'view'),
    ('2023-06-13T10:01:00Z', 'user2', 'page2', 'view'),
    ('2023-06-13T10:02:00Z', 'user3', 'page3', 'view'),
    ('2023-06-13T10:03:00Z', 'user4', 'page1', 'view'),
    ('2023-06-13T10:04:00Z', 'user5', 'page2', 'view');
    ``` 

- Query data 
    ```sql
    SELECT * FROM website_visits;
    ``` 
- Result should be:
    ```
    2023-06-13 12:01:00	user2	page2	view
    2023-06-13 12:03:00	user4	page1	view
    2023-06-13 12:02:00	user3	page3	view
    2023-06-13 12:00:00	user1	page1	view
    2023-06-13 12:04:00	user5	page2	view
    ```

## Connect to DigiSpine
### 1st approach: Dump messages directly to a table

- deploy [kconnect-console-producer-json.yml](kconnect-console-producer-json.yml)
- Create a table in RisingWave that connects to DigiSpine / Kafka
  ```sql
  CREATE TABLE dataproduct_table( my_value varchar)
  include key as key_vol
  include timestamp as timestamp_col
  WITH (
  connector='kafka',
  topic='dataproduct',
  properties.bootstrap.server='digispine:9092',
  scan.startup.mode='latest'
  ) FORMAT PLAIN ENCODE JSON;
  ```
- Query data from table (standard postgres)
    ```sql
    SELECT * FROM dataproduct_table;
    ```
- Result should look as follows. Note: Only total_visits include valid data, that changes after each query
   ```
  my_value        timestamp_col           key_vol
  MyCounter 180	2024-03-04 15:28:26	(null)
  MyCounter 181	2024-03-04 15:28:27	(null)
  MyCounter 182	2024-03-04 15:28:28	(null)
  MyCounter 183	2024-03-04 15:28:29	(null)
  MyCounter 184	2024-03-04 15:28:30	(null)
  ```

### 2nd approach: Perform stream processing on messages
#### Create a stream 
- Create a source stream in RisingWave that connects to DigiSpine / Kafka and receives messages
    ```sql
    CREATE SOURCE IF NOT EXISTS flugdaten_stream (
    timestamp timestamp with time zone,
    flugdaten_value varchar
    )
    INCLUDE timestamp as timestamp
    WITH (
    connector='kafka',
    topic='flugdaten',
    properties.bootstrap.server='digispine:9092',
    scan.startup.mode='earliest'
    ) FORMAT PLAIN ENCODE JSON;
    ```
#### Create a materialized view that combines/processes data
- Create a materialized view that performs stream processing/transformation so that we get  data we offer as product. 
    ```sql
    CREATE MATERIALIZED VIEW flugdaten_stream_mv AS
    SELECT flugdaten_value,
    count(*) AS total_visits,
    count(DISTINCT flugdaten_value) AS unique_visitors,
    max(timestamp) AS last_visit_time
    FROM flugdaten_stream
    GROUP BY flugdaten_value;
    ```
- Query data from materialized view (standard postgres)
    ```sql
    SELECT * FROM flugdaten_stream_mv;
    ```
- Result should look as follows. Note: Only total_visits include valid data, that changes after each query 
   ```
  flugdaten_value	total_visits	unique_visitors	last_visit_time
  (null)	        1124079	        0	            (null)
  ```



## Data product
- Deploy Data product storage
- Upload files to volumes via portainer
  - Upload prometheus.yml to root directory of prometheus volume
  - Upload grafana.ini to root directory of grafana volume
  - Configure dashboards:                     
    - Login to grafana container
    - create directory `/var/lib/grafana/provisioning/dashboards` (Note: If directory is created on volume outside the container, then the path is `/provisioning/dashboards)
    - create directory `/var/lib/grafana/provisioning/datasources` (Note: If directory is created on volume outside the container, then the path is `/provisioning/dashboards)
    - Upload files from grafana/provisioning directory 

## Add Apache Superset as Client
From: https://superset.apache.org/docs/quickstart/
- Deploy `superset.yml`
- https://preset.io/blog/2020-05-18-install-db-drivers/


## Notes: 

### Error messages in RisingWave

- __Connection timeout__: If you see following error message in RisingWave but everything seems to work, a proxy in between (such as ha-proxy) might close the connection and causes the disconnection.   
    ```
    2025-08-25T07:34:32.423706969Z 2025-08-25T07:34:32.423584674Z ERROR rw-streaming madsim_rdkafka::std_::client: librdkafka: Global error: BrokerTransportFailure (Local: Broker transport failure): GroupCoordinator: Disconnected (after 30001ms in state UP, 1 identical error(s) suppressed)```