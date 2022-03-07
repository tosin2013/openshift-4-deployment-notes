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
## Create MD5 hash of added hosts, use as suffix for idempotent IDs
export HOSTS_MD5=$(echo -n "${UNMATCHED_HOSTS[@]}" | md5sum | awk '{print $1}')

#########################################################
## Process Scaling or Reporting action
if [ "$CLUSTER_ALL_HOSTS_REPORTED" == "true" ]; then
  if [ $CLUSTER_ALL_HOSTS_INSTALLED == "true" ]; then
    echo -e "===== All hosts have reported in and are installed!"
    echo -e "  Nothing else to do, exiting...\n"
    exit 0
  else
    echo -e "===== All hosts have reported in but not all hosts are installed!\n"
    echo -e "  Starting cluster installation..."

    #########################################################
    ## Check to see if all the nodes have reported in
    source $SCRIPT_DIR/steps/check-nodes-ready.sh
    
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

  fi
else
  echo -e "===== Not all hosts have been added, scaling up...\n"
  source $SCRIPT_DIR/steps/create-new-add-hosts-cluster.sh

  ###########################################################
  ## Get cluster info
  NEW_CLUSTER_INFO_REQ=$(curl -s --fail \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "${ASSISTED_SERVICE_V2_API}/clusters/$NEW_CLUSTER_ID")

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