#!/bin/bash

set -e

if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
fi

echo -e "\n===== Getting cluster credentials..."

# Query the Cluster for kubeadmin password
CLUSTER_KUBEADMIN_REQ=$(curl -s \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request GET \
"${ASSISTED_SERVICE_V1_API}/clusters/$TARGET_CLUSTER_ID/credentials")


if [ -z "$CLUSTER_KUBEADMIN_REQ" ]; then
  echo "ERROR: Failed to get cluster credentials"
  exit 1
else
  export CLUSTER_CONSOLE_URL=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.console_url')
  export CLUSTER_CONSOLE_KUBEADMIN_USERNAME=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.username')
  export CLUSTER_CONSOLE_KUBEADMIN_PASSWORD=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.password')

  echo -e "\n===== Cluster Credentials ====="
  echo "  kubeadmin Password: ${CLUSTER_CONSOLE_KUBEADMIN_PASSWORD}"
  echo "  Console URL: ${CLUSTER_CONSOLE_URL}"
  echo -e "==============================="
fi

