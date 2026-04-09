#!/bin/sh
USER=$(cat /run/secrets/ops_s3_storage_user)
PASS=$(cat /run/secrets/ops_s3_storage_pw)
printf '[system]\nstate_store = "hummock+minio://%s:%s@%s/%s"\ndata_directory = "%s"\n' \
  "$USER" "$PASS" "$S3_ENDPOINT" "$S3_BUCKET" "$S3_PATH" > /tmp/risingwave.toml
printf '\n[storage.s3]\nendpoint = "%s"\naccess_key = "%s"\nsecret_key = "%s"\n' \
  "$AWS_ENDPOINT_URL" "$USER" "$PASS" >> /tmp/risingwave.toml
exec /risingwave/bin/risingwave "$RW_NODE_TYPE" --config-path /tmp/risingwave.toml $RW_NODE_OPTS
