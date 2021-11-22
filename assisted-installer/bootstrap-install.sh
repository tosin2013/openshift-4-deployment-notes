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
## Check to see if this is a fresh install or scaling

if [ "$CLUSTER_INSTALLED_STARTED" == "false" ]; then
  #########################################################
  ## Fresh install
  
  #########################################################
  ## Set node hostnames and roles
  source $SCRIPT_DIR/steps/set-node-hostnames-and-roles.sh

  #########################################################
  ## Set networking VIPs
  source $SCRIPT_DIR/steps/set-networking.sh

  #########################################################
  ## Check to see if the cluster is ready to install
  source $SCRIPT_DIR/steps/check-cluster-ready-to-install.sh

  #########################################################
  ## Start the Installation
  source $SCRIPT_DIR/steps/start-install.sh
else
  #########################################################
  ## Check to see if the installation has completed
  if [ $CLUSTER_INSTALL_COMPLETED != "2000-01-01T00:00:00.000Z" ]; then
    echo "  Cluster installed on ${CLUSTER_INSTALL_COMPLETED}"

    #########################################################
    ## Check to see if we're scaling up Scaling up
    #echo -e "\n===== Scaling action detected!"

  else
    echo "  Cluster is still installing..."
  fi
fi
