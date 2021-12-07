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

##### Enter Worker Infofmation
#read -p "Enter worker name > " WORKER_NAME
#read -p "Enter woker MAC address > " MAC_ADDRESS
#read -p "Enter IPV4 Address for worker> " IPV4_ADDRESS
#read -p "Enter Gateway for worker> " GATEWAY
#read -p "Enter Network Prefix > " PREFIX
#read -p "Enter Network Interface > " NETWORK_INTERFACE

source ./authenticate-to-api.sh
#export NODE_CFG='{"name": "'${WORKER_NAME}'", "role": "application-node", "mac_address": "'${MAC_ADDRESS}'", "ipv4": {"address": "'${IPV4_ADDRESS}'", "gateway": "'${GATEWAY}'", "prefix": "'${PREFIX}'", "iface": "'${NETWORK_INTERFACE}'"}}'
###################################################
## For Testing 
WORKER_NAME="ocp06"
export NODE_CFG='{"name": "ocp06", "role": "application-node", "mac_address": "52:54:00:00:00:06", "ipv4": {"address": "10.0.1.56", "gateway": "10.0.1.1", "prefix": "24", "iface": "enp1s0"}}'
echo "NODE6_CFG='{\"name\": \"ocp06\", \"role\": \"application-node\", \"mac_address\": \"52:54:00:00:00:06\", \"ipv4\": {\"address\": \"10.0.1.56\", \"gateway\": \"10.0.1.1\", \"prefix\": \"24\", \"iface\": \"enp1s0\"}}'" > /tmp/ocp06.temp
if grep -oq "^NODE6_CFG" ./cluster-vars.sh 
then 
  echo "ocp06 found please remove from ./cluster-vars.sh and try again"
  exit $?
else 
  sed -i "/^####INSERT NEW NODES UNDER HERE*/a $(cat /tmp/ocp06.temp)" cluster-vars.sh
fi 

export NODE_CFGS='{ "nodes": [ '${NODE_CFG}' ] }'

source  $SCRIPT_DIR/nmstate-generator.sh

echo ${CLUSTER_ID}
echo 
#########################################################
## Optional: Configure the ISO with a core user password
if [ ! -z "$CORE_USER_PWD" ]; then
    ## Core user password is set, configure ISO with core user password
    echo -e "\n===== Setting password authentication for core user..."
    sleep 5
    source $SCRIPT_DIR/patch-core-user-password.sh
fi

#########################################################
## Create a new 'AddHost cluster'
export NEW_CLUSTER_ID="$(uuidgen)"

if grep -oq "^export NEW_CLUSTER_ID=.*" ./cluster-vars.sh 
then 
  sed -i "s/^export NEW_CLUSTER_ID=.*/export NEW_CLUSTER_ID='${NEW_CLUSTER_ID}'/g" cluster-vars.sh
else 
  sed -i "/^###INSERT NEW CLUSTER ID HERE.*/a export NEW_CLUSTER_ID=\'${NEW_CLUSTER_ID}\'" cluster-vars.sh
fi 

POST_NEW_WORKER=$(curl -s -o /dev/null -w "%{http_code}" -X POST  "${ASSISTED_SERVICE_ENDPOINT}/api/assisted-install/v1/add_hosts_clusters" \
    -d "{ \"id\": \"${NEW_CLUSTER_ID}\", \"name\": \"${WORKER_NAME}\", \"api_vip_dnsname\": \"api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS}\", \"openshift_version\": \"${CLUSTER_VERSION}\"}" \
    --header "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN")

echo $POST_NEW_WORKER  
if [ "$POST_NEW_WORKER" -ne "201" ]; then
    echo "===== Failed to add new worker to cluster!"
    exit 1
fi

curl -s -X GET "${ASSISTED_SERVICE_ENDPOINT}/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"  -H "Authorization: Bearer $ACTIVE_TOKEN"| jq -r '.[].id'|  grep $NEW_CLUSTER_ID

#########################################################
## Configure the ISO
source $SCRIPT_DIR/configure-discovery-iso.sh ${WORKER_NAME} ${NEW_CLUSTER_ID}

echo "Starting cluster installation..."
blank=""
for x in $(cat cluster-vars.sh | grep -oE ^NODE.*_CFG= | sed 's/=//')
do
  updatestring="'\${${x}}',"
  echo $x
  blank+=${updatestring}
  echo $blank | sed 's/.$//'
  final_string=$(echo $blank | sed 's/.$//')
  echo "NODE_CFGS='{ \"nodes\": [ ${final_string} ] }'" > /tmp/node_config.temp
  cat /tmp/node_config.temp
done

sed -i "s/^export NODE_CFGS=.*/export $(cat /tmp/node_config.temp)/g" cluster-vars.sh


#########################################################
## Download the ISO
export WORKER_ISO_NAME="ai-liveiso-$NEW_CLUSTER_ID-$WORKER_NAME"
source $SCRIPT_DIR/download-iso.sh ${WORKER_ISO_NAME} ${NEW_CLUSTER_ID}
echo "Boot node with ISO then press any key to continue."
echo "*********************************************"
echo "If you are using the Hack-y scripts for kvm open a new session and run the following"
echo "export NEW_CLUSTER_ID=${NEW_CLUSTER_ID}"
echo "export WORKER_NAME=${WORKER_NAME}"
echo "./hack/create-kvm-vms.sh"
echo "*********************************************"
read -p "Have your booted ${WORKER_NAME} with ${WORKER_ISO_NAME}? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit $?
fi


source ./cluster-vars.sh

#########################################################
## Get Node Difference
UNMATCHED_HOSTS_COUNT=1

#########################################################
## Check to See if nodes are ready
source $SCRIPT_DIR/steps/check-nodes-ready.sh

#########################################################
## Set node hostnames and roles
source $SCRIPT_DIR/steps/set-node-hostnames-and-roles.sh 

#########################################################
## Check to see if the cluster is ready to install
#export NEW_CLUSTER_ID=$NEW_CLUSTER_ID;source $SCRIPT_DIR/steps/check-cluster-ready-to-install.sh

#########################################################
## Start the Installation
source $SCRIPT_DIR/steps/start-install.sh

#########################################################
## Query the API for cluster status, ensure it is installed
source $SCRIPT_DIR/steps/wait-for-cluster-install.sh

