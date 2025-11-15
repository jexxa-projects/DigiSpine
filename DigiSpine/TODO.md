## Obvious TODOs

- [ ] Secure external connection protocols?! (e.g. SSL, alternatively use encrypted overlay network?)
  - https://docs.confluent.io/platform/current/kafka/authentication_ssl.html
  - https://dockerlabs.collabnix.com/advanced/security/networking/
- [ ] Validate usage of ksql now -> Most important features such as josn-explode are only in 0.29 -> Instead use risingwave.
- [] Interfaces to be exposed to outside?

## Decisions so far
- [x] validate data/log storage so that they are stored in a separate volume and exist after update/location rotation ins swarm
- [x] Which image -> Confluent due to their support time and possibility to commercial support  
  - Note: Versioning of confluent
    - https://docs.confluent.io/platform/current/installation/versions-interoperability.html 
