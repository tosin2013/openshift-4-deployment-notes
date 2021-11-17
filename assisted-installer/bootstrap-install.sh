#!/bin/bash

set -e

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

if [ -z "$CLUSTER_ID" ]; then
  echo -e "\n===== No Cluster ID found! Run ./bootstrap-create.sh first!\n"
  exit 1
fi

#########################################################
## Check to see if all the nodes have reported in
source $SCRIPT_DIR/steps/check-nodes-ready.sh

#########################################################
## Set node hostnames and roles
source $SCRIPT_DIR/steps/set-node-hostnames-and-roles.sh