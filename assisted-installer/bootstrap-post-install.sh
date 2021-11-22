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
source $SCRIPT_DIR/steps/wait-for-cluster-install.sh

#########################################################
## Pull the default kubeadmin credentials
source $SCRIPT_DIR/steps/get-credentials.sh

echo -e "====="
echo -e "===== Installation complete!"
echo -e "====="

echo -e "From this point you could automate other functions, such as storage, identity, default workloads, and more!\n"