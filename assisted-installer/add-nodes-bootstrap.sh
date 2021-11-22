#!/bin/bash
set -x
set -e

##### creating addhost cluster
source ./cluster-vars.sh

##### Enter Worker Infofmation
read -p "Enter worker name > " WORKER_NAME
read -p "Enter woker MAC address > " MAC_ADDRESS
read -p "Enter IPV4 Address for worker> " IPV4_ADDRESS
read -p "Enter Gateway for worker> " GATEWAY
read -p "Enter Network Prefix > " PREFIX
read -p "Enter Network Interface > " NETWORK_INTERFACE

source ./authenticate-to-api.sh
export NODE_CFG='{"name": "'${WORKER_NAME}'", "mac_address": "'${MAC_ADDRESS}'", "ipv4": {"address": "'${IPV4_ADDRESS}'", "gateway": "'${GATEWAY}'", "prefix": "'${PREFIX}'", "iface": "'${NETWORK_INTERFACE}'"}}'
#WORKER_NAME="ocp04"
#export NODE_CFG='{"name": "ocp04", "mac_address": "52:54:00:00:00:04", "ipv4": {"address": "192.168.123.54", "gateway": "192.168.123.1", "prefix": "24", "iface": "enp1s0"}}'
export NODE_CFGS='{ "nodes": [ '${NODE_CFG}' ] }'

source  $SCRIPT_DIR/nmstate-generator.sh

echo ${CLUSTER_ID}

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
NCLUSTER_ID="$(uuidgen)"
echo $NCLUSTER_ID

POST_NEW_WORKER=$(curl -s -o /dev/null -w "%{http_code}" -X POST  "${ASSISTED_SERVICE_ENDPOINT}/api/assisted-install/v1/add_hosts_clusters" \
    -d "{ \"id\": \"${NCLUSTER_ID}\", \"name\": \"${WORKER_NAME}\", \"api_vip_dnsname\": \"api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS}\", \"openshift_version\": \"${CLUSTER_VERSION}\"}" \
    --header "Content-Type: application/json" \
    -H "Authorization: Bearer $ACTIVE_TOKEN")

echo $POST_NEW_WORKER  
if [ "$POST_NEW_WORKER" -ne "201" ]; then
    echo "===== Failed to add new worker to cluster!"
    exit 1
fi

curl -s -X GET "${ASSISTED_SERVICE_ENDPOINT}/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"  -H "Authorization: Bearer $ACTIVE_TOKEN"| jq -r '.[].id'|  grep $NCLUSTER_ID

#########################################################
## Configure the ISO
source $SCRIPT_DIR/configure-discovery-iso.sh ${WORKER_NAME} ${NCLUSTER_ID}

#########################################################
## Download the ISO
export WORKER_ISO_NAME="ai-liveiso-$NCLUSTER_ID-$WORKER_NAME"
source $SCRIPT_DIR/download-iso.sh ${WORKER_ISO_NAME} ${NCLUSTER_ID}