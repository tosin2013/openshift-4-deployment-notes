#!/bin/bash

set -e
source cluster-vars.sh
source authenticate-to-api.sh

if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
  NUMBER_OF_CFG_NODES=$(echo $NODE_CFGS | jq -r '.[] | length')
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
  NUMBER_OF_CFG_NODES="$UNMATCHED_HOSTS_COUNT"
fi

LOOP_ON="true"
CYCLE_TIME_IN_SECONDS="10"

echo -e "\n===== Waiting for the cluster to be ready to install..."

## Loop de' loop
while [ $LOOP_ON = "true" ]; do
  # Query the Cluster for Information around its composition
  CLUSTER_INFO_REQ=$(curl -s --fail \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "${ASSISTED_SERVICE_V2_API}/clusters/$TARGET_CLUSTER_ID")

  if [ -z "$CLUSTER_INFO_REQ" ]; then
    echo "ERROR ${CLUSTER_INFO_REQ}: Failed to get cluster information "
    exit 1
  fi

  ## Debug
  #echo $CLUSTER_INFO_REQ | python3 -m json.tool

  CLUSTER_STATUS=$(echo $CLUSTER_INFO_REQ | jq -r '.status')
  CLUSTER_INSTALL_STARTED=$(echo $CLUSTER_INFO_REQ | jq -r '.install_started_at')
  CLUSTER_INSTALL_COMPLETED=$(echo $CLUSTER_INFO_REQ | jq -r '.install_completed_at')
  NUMBER_OF_HOSTS_READY=$(echo $CLUSTER_INFO_REQ | jq -r '.ready_host_count')

  ## Check if cluster has already been installed (date check)
  if [ $CLUSTER_INSTALL_STARTED == "2000-01-01T00:00:00.000Z" ]; then
    echo "  Cluster has not been installed yet..."
    ## Check if all nodes have reported in
    if [ $NUMBER_OF_HOSTS_READY -eq $NUMBER_OF_CFG_NODES ]; then
      echo "  All nodes have reported in!"
      if [ $CLUSTER_STATUS == "ready" ]; then
        echo "  Cluster is ready to install!"
        LOOP_ON="false"
      else
        echo "  Cluster is not ready to install..."
      fi
    else
      echo "  Not all nodes have reported in yet..."
      echo "  Waiting for the cluster to be ready to install..."
      sleep $CYCLE_TIME_IN_SECONDS
    fi
  else
    echo "  Cluster install has already started!"
    if [ $CLUSTER_INSTALL_COMPLETED != "2000-01-01T00:00:00.000Z" ]; then
      echo "  Cluster installed on ${CLUSTER_INSTALL_COMPLETED}"
    else
      echo "  Cluster is still installing..."
    fi
    LOOP_ON="false"
  fi

done