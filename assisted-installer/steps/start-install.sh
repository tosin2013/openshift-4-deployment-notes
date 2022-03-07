#!/bin/bash

set -e
source cluster-vars.sh
source authenticate-to-api.sh
if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
  API_ENDPOINT="${ASSISTED_SERVICE_V2_API}/clusters/$TARGET_CLUSTER_ID/actions/install"
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
  API_ENDPOINT="${ASSISTED_SERVICE_V1_API}/clusters/$TARGET_CLUSTER_ID/actions/install_hosts"
fi

echo -e "\n===== Starting cluster installation..."

# Start the Installer
START_INSTALLATION_REQ=$(curl -s --fail \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
"${API_ENDPOINT}")

if [ -z "$START_INSTALLATION_REQ" ]; then
  echo "ERROR: Failed to start cluster install"
  exit 1
fi