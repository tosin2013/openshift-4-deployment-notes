#!/bin/bash

set -e

echo -e "===== Waiting for cluster installation to complete..."

LOOP_ON="true"
CYCLE_TIME_IN_SECONDS="10"

while [ $LOOP_ON = "true" ]; do
  # Query the Assisted Installer Service for Cluster Status
  CLUSTER_INFO_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID")

  CLUSTER_STATUS=$(echo $CLUSTER_INFO_REQ | jq -r '.status')

  if [[ $CLUSTER_STATUS = "installed" ]]; then
    LOOP_ON="false"
    echo -e "  Cluster has finished installing!\n"
  else
    echo "  Waiting for cluster to be fully installed and ready...waiting $CYCLE_TIME_IN_SECONDS seconds..."
    sleep $CYCLE_TIME_IN_SECONDS
  fi

done