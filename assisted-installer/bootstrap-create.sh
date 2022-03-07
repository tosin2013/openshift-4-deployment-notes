#!/bin/bash

#set -e

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

#########################################################
## Perform preflight checks
source $SCRIPT_DIR/preflight.sh

#########################################################
## Check to see if the Cluster has already been created
if [ -z "$CLUSTER_ID" ]; then
  ## Cluster has not been created yet, add to the AI Service
  echo -e "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} not found, creating now...\n"
  source $SCRIPT_DIR/create-cluster.sh
else
  ## Cluster has already been created, ensure it is configured
  echo -e "===== Cluster ${CLUSTER_NAME}.${CLUSTER_BASE_DNS} has already been created, continuing with the configuration process..."
  echo "  CLUSTER_ID: ${CLUSTER_ID}"
fi

source ./cluster-vars.sh

#########################################################
## Check to see if the InfraEnv has already been created
if [ -z "$INFRAENV_ID" ]; then
  ## InfraEnv has not been created yet, add to the AI Service
  echo -e "===== InfraEnv ${CLUSTER_NAME} not found, creating now...\n"
  source $SCRIPT_DIR/steps/create-infraenv.sh
else
  ## Cluster has already been created, ensure it is configured
  echo -e "===== Cluster ${CLUSTER_NAME} has already been created, continuing with the configuration process..."
  echo "  INFRAENV_ID: ${INFRAENV_ID}"
fi

source ./cluster-vars.sh

#########################################################
## Generate Network Configuration Files
source $SCRIPT_DIR/nmstate-generator.sh

#########################################################
## Optional: Configure the ISO with a core user password
if [ ! -z "$CORE_USER_PWD" ]; then
  ## Core user password is set, configure ISO with core user password
  echo -e "\n===== Setting password authentication for core user..."
  sleep 5
  source $SCRIPT_DIR/patch-core-user-password.sh
fi

#########################################################
## Configure the ISO
source $SCRIPT_DIR/configure-discovery-iso.sh

#########################################################
## Download the ISO
source $SCRIPT_DIR/download-iso.sh
