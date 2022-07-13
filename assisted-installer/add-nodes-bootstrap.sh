#!/bin/bash
#set -x
set -e

#########################################################
## Check for required cluster-vars.sh file
if [ ! -f "./cluster-vars.sh" ]; then
  echo -e "\n===== No cluster-vars.sh file found!\n"
  exit 1
else
  source ./cluster-vars.sh
fi

###################################################
## For Testing 
#WORKER_NAME="ocp06"
#MAC_ADDRESS="52:54:00:00:00:06"
#IPV4_ADDRESS=192.168.1.10
#GATEWAY=192.168.1.1
#PREFIX=24
#NETWORK_INTERFACE=enp1s0

function add_hosts_to_list(){
    
  ##### Enter Worker Infofmation
  read -p "Enter worker name Example: ocp06> " WORKER_NAME
  read -p "Enter worker MAC address Example: 52:54:00:00:00:06> " MAC_ADDRESS
  read -p "Enter IPV4 Address for worker Example: 192.168.1.10> " IPV4_ADDRESS
  read -p "Enter Gateway for worker Example: 192.168.1.1> " GATEWAY
  read -p "Enter Network Prefix Example: 24> " PREFIX
  read -p "Enter Network Interface Example: enp1s0> " NETWORK_INTERFACE

  source ./authenticate-to-api.sh
  if [ $MULTI_NETWORK  == false ];
  then
    export NODE_CFG='{"name": "'${WORKER_NAME}'", "role": "application-node", "mac_address": "'${MAC_ADDRESS}'", "ipv4": {"address": "'${IPV4_ADDRESS}'", "gateway": "'${GATEWAY}'", "prefix": "'${PREFIX}'", "iface": "'${NETWORK_INTERFACE}'"}}'
    echo "NODE${WORKER_NAME}_CFG='{\"name\": \"${WORKER_NAME}\", \"role\": \"application-node\", \"mac_address\": \"${MAC_ADDRESS}\", \"ipv4\": {\"address\": \"${IPV4_ADDRESS}\", \"gateway\": \"${GATEWAY}\", \"prefix\": \"${PREFIX}\", \"iface\": \"${NETWORK_INTERFACE}\"}}'" > /tmp/${WORKER_NAME}.temp
  elif [ $MULTI_NETWORK == true ];
  then 
    read -p "Enter worker MAC address Example: 52:54:00:00:00:07> " MAC_ADDRESS_INT2

    read -p "Enter IPV4 Address for worker Example: 192.168.100.10> " IPV4_ADDRESS_INT2

    read -p "Enter Gateway for worker Example: 192.168.100.1> " GATEWAY_INT2

    read -p "Enter Network Interface Example: enp1s1> " NETWORK_INTERFACE_INT2

    read -p "Enter Network Prefix Example: 24> " PREFIX_INT2

    export NODE_CFG='{"name": "'${WORKER_NAME}'", "role": "application-node", "mac_address_int1": "'${MAC_ADDRESS}'", "ipv4_int1": {"address": "'${IPV4_ADDRESS}'", "gateway": "'${GATEWAY}'", "prefix": "'${PREFIX}'", "iface": "'${NETWORK_INTERFACE}'"}, "mac_address_int2": "'${MAC_ADDRESS_INT2}'", "ipv4_int2": {"address": "'${IPV4_ADDRESS_INT2}'", "gateway": "'${GATEWAY_INT2}'", "prefix": "'${PREFIX_INT2}'", "iface": "'${NETWORK_INTERFACE_INT2}'"}}'
    echo "NODE${WORKER_NAME}_CFG='{\"name\": \"${WORKER_NAME}\", \"role\": \"application-node\", \"mac_address_int1\": \"${MAC_ADDRESS}\", \"ipv4_int1\": {\"address\": \"${IPV4_ADDRESS}\", \"gateway\": \"${GATEWAY}\", \"prefix\": \"${PREFIX}\", \"iface\": \"${NETWORK_INTERFACE}\"}, \"mac_address_int2\": \"${MAC_ADDRESS_INT2}\", \"ipv4_int2\": {\"address\": \"${IPV4_ADDRESS_INT2}\", \"gateway\": \"${GATEWAY_INT2}\", \"prefix\": \"${PREFIX_INT2}\", \"iface\": \"${NETWORK_INTERFACE_INT2}\"}}'" > /tmp/${WORKER_NAME}.temp
  fi
  ###################################################
  ## NODE Check

  if grep -oq "*${IPV4_ADDRESS_INT2}*" ./cluster-vars.sh 
  then 
    echo "${IPV4_ADDRESS_INT2} found please remove  or add a difffent one from ./cluster-vars.sh and try again"
    exit $?
  fi 

  if grep -oq "*${MAC_ADDRESS_INT2}*" ./cluster-vars.sh 
  then 
    echo "${MAC_ADDRESS_INT2} found please remove or add a difffent one from ./cluster-vars.sh and try again"
    exit $?
  fi 

  if grep -oq "^NODE${WORKER_NAME}_CFG" ./cluster-vars.sh 
  then 
    echo "${WORKER_NAME} found please remove from ./cluster-vars.sh and try again"
    exit $?
  else 
    sed -i "/^####INSERT NEW NODES UNDER HERE*/a $(cat /tmp/${WORKER_NAME}.temp)" cluster-vars.sh
  fi 

}

while true 
do 
	read -p "Would you like to add an new machine to cluster: " yn
   case $yn in
        [Yy]* ) add_hosts_to_list;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "############################################################"
echo " Run the ./bootstrap-scale-up.sh script to add new nodes to the cluster"
echo "############################################################"