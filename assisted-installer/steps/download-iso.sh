#!/bin/bash

set -e

echo -e "\n===== Waiting 15s for ISO to build...\n"
sleep 15

if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
  ISO_SAVE_PATH="${CLUSTER_DIR}/ai-liveiso-$TARGET_CLUSTER_ID.iso"
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
  ISO_SAVE_PATH="${CLUSTER_DIR}/ai-liveiso-addhosts-$TARGET_CLUSTER_ID.iso"
fi

## Download Discovery ISO
echo -e "\n===== Downloading Discovery ISO locally to ${ISO_SAVE_PATH} ...\n"
curl \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  -L "${ASSISTED_SERVICE_V2_API}/clusters/$TARGET_CLUSTER_ID/downloads/image" \
  -o ${ISO_SAVE_PATH}
