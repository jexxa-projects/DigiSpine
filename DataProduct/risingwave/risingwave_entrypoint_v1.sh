#!/bin/sh
set -e

# 1. Secrets auslesen und als Standard-AWS-Variablen exportieren
# RisingWave erkennt diese Variablen automatisch für den S3-Zugriff
export AWS_ACCESS_KEY_ID=$(cat /run/secrets/ops_s3_storage_user)
export AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/ops_s3_storage_pw)
# In der entrypoint.sh vor dem exec ergänzen:
export CONTAINER_IP=$(hostname -i)

# 2. Minimale TOML Datei ohne den veralteten [storage.s3] Block
cat <<EOF > /tmp/risingwave.toml
[system]
state_store = "hummock+minio://${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}@${S3_ENDPOINT}/${S3_BUCKET}"
data_directory = "${S3_PATH}"

[storage]
# Falls du Pfad-basierten Zugriff für MinIO erzwingen willst:
# is_shared_buffer_enabled = true
EOF

# 3. Starten der Komponente
if [ "$RW_NODE_TYPE" = "compute-node" ]; then
  # RW_NODE_OPTS dynamisch überschreiben
  RW_NODE_OPTS="$RW_NODE_OPTS --advertise-addr ${CONTAINER_IP}:5688"
fi

exec /risingwave/bin/risingwave "$RW_NODE_TYPE" --config-path /tmp/risingwave.toml $RW_NODE_OPTS
