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

function cluster_install_steps(){
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
}

function prompt_confirm() {
  while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) cluster_install_steps ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac 
  done  
}

#########################################################
## Check to see if all the nodes have reported in
source $SCRIPT_DIR/steps/check-nodes-ready.sh

#########################################################
## Check to see if this is a fresh install or scaling

if [ "$CLUSTER_INSTALLED_STARTED" == "false" ]; then
  #########################################################
  ## Fresh install
  #source $SCRIPT_DIR/steps/check-nodes-ready.sh
  cluster_install_steps

else
  #########################################################
  ## Check to see if the installation has completed
  if [ $CLUSTER_INSTALL_COMPLETED != "0001-01-01T00:00:00.000Z" ]; then
    echo "  Cluster installed on ${CLUSTER_INSTALL_COMPLETED}"

    #########################################################
    ## Check to see if we're scaling up Scaling up
    #echo -e "\n===== Scaling action detected!"

  else
    echo "Cluster is still installing..."
      
    if [[ $CLUSTER_STATUS == "installing" ]];
    then
      echo "Cluster is currently ${CLUSTER_STATUS}"
      echo "Please monitor cluster @ https://console.redhat.com/openshift/"
      exit
    elif [[ $CLUSTER_STATUS == "pending-for-input" ]];
    then 
      prompt_confirm "The Current status is pending-for-input would you like to automatially resolve?" 
    elif [[ $CLUSTER_STATUS == "ready" ]];
    then 
      source $SCRIPT_DIR/steps/start-install.sh
    elif [[ $CLUSTER_HAS_ALL_HOSTS == "false"  ||  $CLUSER_HOSTS_RENAMED == "false"  || $CLUSER_ROLE_TAGGED == "false" ]];
    then 
      cluster_install_steps
    else 
      echo "An issue may have occured during install Curent status $CLUSTER_STATUS"
      echo "Please monitor cluster @ https://console.redhat.com/openshift/"
      exit
    fi
  fi
fi
