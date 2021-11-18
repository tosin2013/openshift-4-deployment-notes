#!/bin/bash

set -e

LOOP_ON="true"
CYCLE_TIME_IN_SECONDS="10"

echo -e "\n===== Checking for nodes and if they are ready to install..."

## Loop de' loop
while [ $LOOP_ON = "true" ]; do

  ## Query API for cluster status
  CLUSTER_INFO_REQ=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID")

  ## Debug
  #echo $CLUSTER_INFO_REQ | python3 -m json.tool

  ## Set variables
  CLUSTER_STATUS=$(echo $CLUSTER_INFO_REQ | jq -r '.status')
  CLUSTER_INSTALL_STARTED=$(echo $CLUSTER_INFO_REQ | jq -r '.install_started_at')
  CLUSTER_INSTALL_COMPLETED=$(echo $CLUSTER_INFO_REQ | jq -r '.install_completed_at')
  NUMBER_OF_HOSTS=$(echo $CLUSTER_INFO_REQ | jq -r '.hosts | length')
  NUMBER_OF_CFG_NODES=$(echo $NODE_CFGS | jq -r '.[] | length')

  ## Overall process:
  ## - Check if cluster has already been installed (date check)
  ##   - FALSE: Check if all nodes have reported in
  ##     - FALSE: Loop until they have
  ##     - TRUE: Continue with execution
  ##   - TRUE: Check if all the nodes are present
  ##     - FALSE: if not then this is a day 2 scaling up action
  ##     - TRUE: Cluster configuration and install complete, continue

  ## Check to see if the install has started
  if [ $CLUSTER_INSTALL_STARTED == "2000-01-01T00:00:00.000Z" ]; then
    ## Cluster has not been installed yet
    if [ "$NUMBER_OF_HOSTS" -eq "$NUMBER_OF_CFG_NODES" ]; then
      ## All nodes have reported in
      echo -e "  All nodes reported in! Continuing with new cluster installation..."
      LOOP_ON="false"
      export CLUSTER_HAS_ALL_HOSTS="true"
      export CLUSTER_INSTALLED_STARTED="false"
    else
      ## Not all nodes have reported in yet
      echo -e "  Cluster install has not started yet! Found ${NUMBER_OF_HOSTS}/${NUMBER_OF_CFG_NODES} hosts reported into the API...sleeping for ${CYCLE_TIME_IN_SECONDS}s..."
      sleep $CYCLE_TIME_IN_SECONDS
    fi
  else
    ## Cluster has been installed
    echo -e "  Cluster install has already started!\n"
    if [ "$NUMBER_OF_HOSTS" -eq "$NUMBER_OF_CFG_NODES" ]; then
      ## All nodes have reported in
      echo -e "  Cluster installed with all nodes!  Continuing with cluster post-configuration...\n"
      export CLUSTER_HAS_ALL_HOSTS="true"
      export CLUSTER_INSTALLED_STARTED="true"
    else
      ## Not all nodes have reported in
      echo -e "  Not all nodes have reported in! Found ${NUMBER_OF_HOSTS}/${NUMBER_OF_CFG_NODES} hosts reported into the API...continuing with scaling action..."
      export CLUSTER_HAS_ALL_HOSTS="false"
      export CLUSTER_INSTALLED_STARTED="true"
    fi
    LOOP_ON="false"
  fi

done
