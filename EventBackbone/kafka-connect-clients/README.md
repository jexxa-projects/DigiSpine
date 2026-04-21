# Example stacks based on kafka-connect to connect to DigiSpine

## Overview 

| Name                      | Description                                                                                |
|---------------------------|--------------------------------------------------------------------------------------------|
| kconnect-console-producer | Message produces messages in 5 seconds interval 'MyCounter <counter>' on topic 'flugdaten' |
| kconnect-console-consumer | Reads messages from topic 'flugdaten' and writes them to stdout                            |