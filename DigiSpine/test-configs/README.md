# Tests to get an idea how kafka-connect works

## Install confluent-hub 

./connect-standalone etc/connect-standolone.properties etc/connect-file-source.properties etc/connect-file-sink.properties


## Simple tests

- Based on https://www.baeldung.com/kafka-connectors-guide

- Start connect-standalone (requires a running kafka-broker)
 ``` 
./connect-standalone etc/connect-standolone.properties etc/connect-file-source.properties etc/connect-file-sink.properties
``` 
- Then 
``` 
  michael@Michaels-Mac-mini-2 bin % echo -e "foo\nbar\n" > test.txt              
  michael@Michaels-Mac-mini-2 bin % echo -e "foo2\nbar2\n" >> test.txt
  michael@Michaels-Mac-mini-2 bin % echo -e "foo\nbar\n" > test.txt 
``` 

## JMS-Connection 
TODO: Work in progress!!! HACKED NOTES DURING TESTING!!!

 
* Install JMS Sink connector: `confluent-hub install confluentinc/kafka-connect-jms:latest`
* Install artemis-client into /Volumes/WorkspaceMac/Entwicklung/confluent-7.2.2/share/confluent-hub-components/confluentinc-kafka-connect-jms/lib: https://repo1.maven.org/maven2/org/apache/activemq/artemis-jms-client-all/2.6.0/artemis-jms-client-all-2.6.0.jar
* Important: Create topic for confluent-licenses manually. Otherwise replication-factor 3 is used (topic.creation.default.replication.factor=1 does not work): `./kafka-topics.sh --create --topic _confluent-command --bootstrap-server localhost:9092`
* Start kafka-connect: `./connect-standalone etc/connect-standolone.properties etc/connect-jms-source.properties` 
* Start AlarmIT's Telegrammeinspieler: michael@Michaels-Mac-mini-2 AlarmIT % `java -jar  "-Dio.jexxa.config.import=src/test/resources/jexxa-test.properties" target/telegrameinspieler-jar-with-dependencies.jar`
* Start Kafka Console Consumer: `./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic MyKafkaTopicName --from-beginning`

=> Result OK: You should see messages from Telegrameinspieler on kafka-console-consumer 



## Issues found

- jms-source does not perform any reconnection (simulated by sleep)? Current workaround: Restart kafka-connect  
```
  [2022-10-31 16:11:08,746] INFO [jms-source|task-0] [Producer clientId=connector-producer-jms-source-0] Node -1 disconnected. (org.apache.kafka.clients.NetworkClient:935)
  [2022-10-31 16:12:05,578] INFO [jms-source|task-0] [AdminClient clientId=connector-adminclient-jms-source-0] Node 1 disconnected. (org.apache.kafka.clients.NetworkClient:935)
  [2022-10-31 16:17:05,682] INFO [jms-source|task-0] [AdminClient clientId=connector-adminclient-jms-source-0] Node 1 disconnected. (org.apache.kafka.clients.NetworkClient:935)
  [2022-10-31 16:22:05,879] INFO [jms-source|task-0] [AdminClient clientId=connector-adminclient-jms-source-0] Node 1 disconnected. (org.apache.kafka.clients.NetworkClient:935)
  [2022-10-31 16:27:05,995] INFO [jms-source|task-0] [AdminClient clientId=connector-adminclient-jms-source-0] Node 1 disconnected. (org.apache.kafka.clients.NetworkClient:935)
  [2022-10-31 17:28:11,781] ERROR [jms-source|task-0] WorkerSourceTask{id=jms-source-0} Task threw an uncaught and unrecoverable exception. Task is being killed and will not recover until manually restarted (org.apache.kafka.connect.runtime.WorkerTask:195)
  org.apache.kafka.connect.errors.ConnectException: Failed on attempt 1 of 2147483647 to receive JMS message: javax.jms.IllegalStateException: AMQ119017: Consumer is closed
  at io.confluent.connect.utils.retry.RetryPolicy.callWith(RetryPolicy.java:423)
  at io.confluent.connect.utils.retry.RetryPolicy.call(RetryPolicy.java:337)
  at io.confluent.connect.jms.core.source.BaseJmsSourceTask.poll(BaseJmsSourceTask.java:289)
  at org.apache.kafka.connect.runtime.WorkerSourceTask.poll(WorkerSourceTask.java:305)
  at org.apache.kafka.connect.runtime.WorkerSourceTask.execute(WorkerSourceTask.java:249)
  at org.apache.kafka.connect.runtime.WorkerTask.doRun(WorkerTask.java:188)
  at org.apache.kafka.connect.runtime.WorkerTask.run(WorkerTask.java:243)
  at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515)
  at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
  at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128)
  at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628)
  at java.base/java.lang.Thread.run(Thread.java:834)
  Caused by: org.apache.kafka.connect.errors.ConnectException: javax.jms.IllegalStateException: AMQ119017: Consumer is closed
  at io.confluent.connect.jms.core.source.BaseJmsSourceTask.receive(BaseJmsSourceTask.java:201)
  at io.confluent.connect.jms.core.source.BaseJmsSourceTask.lambda$poll$0(BaseJmsSourceTask.java:291)
  at io.confluent.connect.utils.retry.RetryPolicy.lambda$call$1(RetryPolicy.java:337)
  at io.confluent.connect.utils.retry.RetryPolicy.callWith(RetryPolicy.java:417)
  ... 11 more
  Caused by: javax.jms.IllegalStateException: AMQ119017: Consumer is closed
  at org.apache.activemq.artemis.core.client.impl.ClientConsumerImpl.checkClosed(ClientConsumerImpl.java:943)
  at org.apache.activemq.artemis.core.client.impl.ClientConsumerImpl.receive(ClientConsumerImpl.java:195)
  at org.apache.activemq.artemis.core.client.impl.ClientConsumerImpl.receive(ClientConsumerImpl.java:379)
  at org.apache.activemq.artemis.jms.client.ActiveMQMessageConsumer.getMessage(ActiveMQMessageConsumer.java:211)
  at org.apache.activemq.artemis.jms.client.ActiveMQMessageConsumer.receive(ActiveMQMessageConsumer.java:132)
  at io.confluent.connect.jms.core.source.JmsClientHelper.receive(JmsClientHelper.java:218)
  at io.confluent.connect.jms.core.source.BaseJmsSourceTask.receive(BaseJmsSourceTask.java:182)
  ... 14 more
  Caused by: ActiveMQObjectClosedException[errorType=OBJECT_CLOSED message=AMQ119017: Consumer is closed]
  ... 21 more
  [2022-10-31 17:28:11,810] INFO [jms-source|task-0] Closing JMS connection (io.confluent.connect.jms.core.source.BaseJmsSourceTask:423)
  [2022-10-31 17:28:11,812] INFO [jms-source|task-0] [Producer clientId=connector-producer-jms-source-0] Closing the Kafka producer with timeoutMillis = 30000 ms. (org.apache.kafka.clients.producer.KafkaProducer:1249)
```

- restart worker does not work/restarts worker `curl -X POST http://localhost:8083/connectors/jms-source/restart` 


## TODO 
- Starting multiple JMS Source/Sinks in one Kafka Connect instance
- Simulating shared connection (zero-downtime-deployment, redundancy, ...)
