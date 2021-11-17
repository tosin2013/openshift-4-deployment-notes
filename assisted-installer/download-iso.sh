#!/bin/bash

set -e

echo -e "\n===== Waiting 15s for ISO to build...\n"
sleep 15

## Download Discovery ISO
echo -e "\n===== Downloading Discovery ISO locally to ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso ...\n"
curl \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  -L "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID/downloads/image" \
  -o ${CLUSTER_DIR}/ai-liveiso-$CLUSTER_ID.iso