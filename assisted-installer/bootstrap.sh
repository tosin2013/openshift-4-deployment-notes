#!/bin/bash

## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

## Check to see if the Cluster has already been created
if [ -z "$CLUSTER_ID" ]; then
  ## Cluster has not been created yet, add to the AI Service
  echo "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} not found, creating now..."
  $SCRIPT_DIR/patch-deployment.sh
else
  ## Cluster has already been created, ensure it is configured
  echo "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} has already been created, continuing with the configuration process..."
fi