# Open Issues

## Runtime Issues

      

## RisingWave
- Configure PWs
- Added new Schema Prod
- Add/Update Hello world


## Superset
- superset-prod.yml does not work -> No connection to postgresDB 
  - Currently, not continued since focus is on metabase 


## Solved 

- Domain-forwarding with HA-Proxy:
  - Solution: After incrementing the accepted connections, problem never occurred again  
  - Writing MVs RisingWave -> Postgres using domain-forwarding with HA-Proxy:
      - Problem:
          - After some time RisingWave could no longer write to Postgres
          - RisingWave and Postgres are no longer reachable via Domain names from outside (DBVisualizer)
          - But they are still reachable via their IP-Addresses (DBVisualizer)
      - Assumption:
          - HA-Proxy has a configured limitation of 20 parallel connections per port
      - Solution (so far)
          - Increase accepted connections to 200 in HA-Proxy
      - Open steps:
          - validate within the next days, if problem arises again

- High Memory load:
  - Solution: Use minio in distributed mode  
  
  - Problem:
      - Each 2-3 days Prometheus informs about high memory load on a node
      - Checking with htop shows glusterfs with high memory load -> This host runs the minio container
  - Assumption:
      - Currently, we use glusterfs + docker-swarm plugin + minio
      - For minio this is a bad setup, because it is not optimized for network file systems and glusterfs is not optimized for small files
  - Workaround:
      - To resolve the high memory load drain corresponding node
  - Open:
      - Try to mount glusterfs on all docker node and use the mount-point with minio
      - If this not works -> use minio distributed mode (requires separate local volumes)
