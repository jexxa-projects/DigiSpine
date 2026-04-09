- Deploy config
- deploy stack
- ALTER USER root WITH PASSWORD 'NeuesSicheresPasswort';

## TODO 
-tls support 

frontend-node:
image: risingwavelabs/risingwave:latest
secrets:
- tls_cert
- tls_key
entrypoint: ["/bin/sh", "-c"]
command: >
/risingwave/bin/risingwave frontend-node
--listen-addr 0.0.0.0:4566
--advertise-addr frontend-node:4566
--meta-addr http://meta-node:5690
--prometheus-listener-addr 0.0.0.0:1250
--health-check-listener-addr 0.0.0.0:6786
--tls-cert-file /run/secrets/tls_cert
--tls-key-file /run/secrets/tls_key