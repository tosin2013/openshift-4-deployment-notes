#!/bin/bash

set -e

echo -e "\n===== Waiting 15s for ISO to build...\n"
sleep 15

if [ ! -z "$INFRAENV_ID" ]; then
  TARGET_CLUSTER_ID="$INFRAENV_ID"
  ISO_SAVE_PATH="${CLUSTER_DIR}/ai-liveiso-$TARGET_CLUSTER_ID.iso"
fi

if [ ! -z "$NEW_INFRAENV_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_INFRAENV_ID"
  ISO_SAVE_PATH="${CLUSTER_DIR}/ai-liveiso-addhosts-$TARGET_CLUSTER_ID.iso"
fi

## Download Discovery ISO
echo -e "\n===== Downloading Discovery ISO locally to ${ISO_SAVE_PATH} ...\n"

GET_DOWNLOAD_LINK=$(curl -H "Authorization: Bearer $ACTIVE_TOKEN" -L "${ASSISTED_SERVICE_V2_API}/infra-envs/$TARGET_CLUSTER_ID")

export DOWNLOAD_LINK=$(printf '%s' "$GET_DOWNLOAD_LINK" | jq -r '.download_url')
  
curl \
  -L "$DOWNLOAD_LINK" \
  -o ${ISO_SAVE_PATH}
