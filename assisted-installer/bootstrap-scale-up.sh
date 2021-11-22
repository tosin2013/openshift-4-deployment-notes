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
## Query the API for cluster status, ensure it is installed
source $SCRIPT_DIR/steps/wait-for-cluster-install.sh

#########################################################
## Query the API for hosts, get difference in hosts
source $SCRIPT_DIR/steps/get-hosts-diff.sh

#########################################################
## Process Scaling or Reporting action
if [ "$CLUSTER_ALL_HOSTS_REPORTED" == "true" ]; then
  if [ $CLUSTER_ALL_HOSTS_INSTALLED == "true" ]; then
    echo -e "===== All hosts have reported in and are installed!"
    echo -e "  Nothing else to do, exiting...\n"
    exit 0
  else
    echo -e "===== All hosts have reported in but not all hosts are installed!\n"
  fi
else
  #########################################################
  ## Create MD5 hash of added hosts, use as suffix for idempotent IDs
  export HOSTS_MD5=$(echo -n "${UNMATCHED_HOSTS[@]}" | md5sum | awk '{print $1}')
  echo -e "===== Not all hosts have been added, scaling up...\n"
  source $SCRIPT_DIR/steps/create-new-add-hosts-cluster.sh

  ###########################################################
  ## Get cluster info
  NEW_CLUSTER_INFO_REQ=$(curl -s --fail \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "${ASSISTED_SERVICE_V1_API}/clusters/$NEW_CLUSTER_ID")

  ## Debug
  #echo "${NEW_CLUSTER_INFO_REQ}" | python3 -m json.tool

  if [ -z "$NEW_CLUSTER_INFO_REQ" ]; then
    echo "ERROR: Failed to get cluster information"
    exit 1
  fi

  #########################################################
  ## TODO: At this point NEW_CLUSTER_INFO_REQ should be
  ## checked for the difference in hosts and the status
  ## of the cluster. If the cluster is not installed,
  ## then continue with the scaling up process.
  ## Continue to check for the hosts and compare them
  ## to the subset of these newly defined hosts
  ## If the cluster is installed, then exit.

  #########################################################
  ## Generate Network Configuration Files
  source $SCRIPT_DIR/nmstate-generator.sh

  #########################################################
  ## Optional: Configure the ISO with a core user password
  if [ ! -z "$CORE_USER_PWD" ]; then
    ## Core user password is set, configure ISO with core user password
    sleep 5
    source $SCRIPT_DIR/steps/patch-core-user-password.sh
  fi

  #########################################################
  ## Configure the ISO
  source $SCRIPT_DIR/steps/configure-discovery-iso.sh

  #########################################################
  ## Download the ISO
  source $SCRIPT_DIR/steps/download-iso.sh

fi