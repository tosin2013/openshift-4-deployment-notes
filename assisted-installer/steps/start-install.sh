#!/bin/bash

set -e

echo -e "\n===== Starting cluster installation..."


# Start the Installer
START_INSTALLATION_REQ=$(curl -s --fail \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
"${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID/actions/install")

if [ -z "$START_INSTALLATION_REQ" ]; then
  echo "ERROR: Failed to start cluster install"
  exit 1
fi