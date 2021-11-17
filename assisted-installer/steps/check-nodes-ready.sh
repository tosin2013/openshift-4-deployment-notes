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

  ## Check to see if the install has started
  if [ $CLUSTER_INSTALL_STARTED == "2000-01-01T00:00:00.000Z" ]; then
    echo -e "  Cluster install has not started yet!"
    sleep $CYCLE_TIME_IN_SECONDS
  else
    echo -e "  Cluster install has already started!\n"
    LOOP_ON="false"
  fi
  
done