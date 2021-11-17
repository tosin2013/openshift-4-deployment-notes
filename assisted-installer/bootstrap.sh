#!/bin/bash

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

#########################################################
## Query the Assisted Installer Service for supported 
##  versions
$SCRIPT_DIR/query-supported-versions.sh

#########################################################
## Check to see if the Cluster has already been created
if [ -z "$CLUSTER_ID" ]; then
  ## Cluster has not been created yet, add to the AI Service
  echo -e "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} not found, creating now...\n"
  $SCRIPT_DIR/create-cluster.sh
  ## Reexport the CLUSTER_ID for use later in the script
  export CLUSTER_ID=$(cat ${CLUSTER_DIR}/.cluster-id.nfo)
else
  ## Cluster has already been created, ensure it is configured
  echo -e "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} has already been created, continuing with the configuration process...\n"
fi

#########################################################
## Generate Network Configuration Files

#########################################################
## Configure the ISO

#########################################################
## Optional: Configure the ISO with a core user password
if [ ! -z "$CORE_USER_PWD" ]; then
  ## Core user password is set, configure ISO with core user password
  echo "===== Setting password authentication for core user..."
  sleep 5
  $SCRIPT_DIR/patch-core-user-password.sh
fi

#########################################################
## Download the ISO
#$SCRIPT_DIR/download-iso.sh