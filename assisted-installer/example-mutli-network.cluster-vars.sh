#!/bin/bash

#set -x
#set -e

export SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})

#########################################################
## Required Files
export SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
export PULL_SECRET_PATH="$HOME/ocp-pull-secret"
export RH_OFFLINE_TOKEN_PATH="$HOME/rh-api-offline-token"

#########################################################
## Required Configuration
export CLUSTER_NAME="ai-poc"
export CLUSTER_BASE_DNS="lab.local"
export CLUSTER_INGRESS_VIP="192.168.3.8"
export CLUSTER_API_VIP="192.168.3.9"
export CLUSTER_MACHINE_NETWORK="192.168.3.0/24"
export NTP_SOURCE="time1.google.com"
export MULTI_NETWORK=true
#########################################################
## Additional Node + Network Configuration
export CLUSTER_NODE_NET_DNS_SERVERS=("192.168.42.9" "192.168.42.10")

## Set Node Network Configuration
NODE1_CFG='{"name": "ocp01", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:01",  "ipv4_int1": {"address": "192.168.3.21", "gateway": "192.168.3.1", "prefix": "24", "iface": "eth0"}, "mac_address_int2": "52:54:00:00:00:11", "ipv4_int2": {"address": "10.0.3.21", "gateway": "10.0.3.1", "prefix": "24", "iface": "eth1"}}'
NODE2_CFG='{"name": "ocp02", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:02",  "ipv4_int1": {"address": "192.168.3.22", "gateway": "192.168.3.1", "prefix": "24", "iface": "eth0"}, "mac_address_int2": "52:54:00:00:00:22", "ipv4_int2": {"address": "10.0.3.22", "gateway": "10.0.3.1", "prefix": "24", "iface": "eth1"}}'
NODE3_CFG='{"name": "ocp03", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:03",  "ipv4_int1": {"address": "192.168.3.23", "gateway": "192.168.3.1", "prefix": "24", "iface": "eth0"}, "mac_address_int2": "52:54:00:00:00:33", "ipv4_int2": {"address": "10.0.3.23", "gateway": "10.0.3.1", "prefix": "24", "iface": "eth1"}}'

NODE4_CFG='{"name": "ocp04", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:04",  "ipv4_int1": {"address": "192.168.3.24", "gateway": "192.168.3.1", "prefix": "24", "iface": "eth0"}, "mac_address_int2": "52:54:00:00:00:44", "ipv4_int2": {"address": "10.0.3.24", "gateway": "10.0.3.1", "prefix": "24", "iface": "eth1"}}'
NODE5_CFG='{"name": "ocp05", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:05",  "ipv4_int1": {"address": "192.168.3.24", "gateway": "192.168.3.1", "prefix": "24", "iface": "eth0"}, "mac_address_int2": "52:54:00:00:00:55", "ipv4_int2": {"address": "10.0.3.25", "gateway": "10.0.3.1", "prefix": "24", "iface": "eth1"}}'
#########################################################
## Remove _ front of variable below to add 3 workers on first install
###_NODE6_CFG='{"name": "ocp06", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:06",  "ipv4_int1": {"address": "192.168.3.26", "gateway": "192.168.3.1", "prefix": "24", "iface": "eth0"}, "mac_address_int2": "52:54:00:00:00:66", "ipv4_int2": {"address": "10.0.3.26", "gateway": "10.0.3.1", "prefix": "24", "iface": "eth1"}}'

#########################################################
####INSERT NEW NODES UNDER HERE

## Add Nodes to the JSON array
export NODE_CFGS='{ "nodes": [ '${NODE1_CFG}', '${NODE2_CFG}', '${NODE3_CFG}', '${NODE4_CFG}', '${NODE5_CFG}' ] }'

### Deploy Controller and worker nodes
### Uncomment to deploy contoller nodes and workers
# export NODE_CFGS='{ "nodes": [ '${NODE1_CFG}', '${NODE2_CFG}', '${NODE3_CFG}', '${NODE4_CFG}', '${NODE5_CFG}', '${NODE6_CFG}' ] }'


#########################################################
### NEW CLUSTER ID for new clusters
###INSERT NEW CLUSTER ID HERE

#########################################################
## Optional Configuration
# ISO_TYPE can be 'minimal-iso' or 'full-iso'
export ISO_TYPE="full-iso"

## CLUSTER_VERSION just needs to be MAJOR.MINOR - actual release is queried from the API
export CLUSTER_VERSION="4.9"
## CLUSTER_RELEASE has been moved to query-supported-versions.sh
#export CLUSTER_RELEASE="4.9.6"

# CORE_USER_PWD - Leave blank to not set a core user password
export CORE_USER_PWD=""

#########################################################
## NOTHING TO SEE HERE - Don't edit past this point

export ASSISTED_SERVICE_HOSTNAME="api.openshift.com"
export ASSISTED_SERVICE_PORT="443" 
export ASSISTED_SERVICE_PROTOCOL="https"
export ASSISTED_SERVICE_ENDPOINT="${ASSISTED_SERVICE_PROTOCOL}://${ASSISTED_SERVICE_HOSTNAME}:${ASSISTED_SERVICE_PORT}"
export ASSISTED_SERVICE_V1_API_PATH="/api/assisted-install/v1"
export ASSISTED_SERVICE_V2_API_PATH="/api/assisted-install/v2"
export ASSISTED_SERVICE_V1_API="${ASSISTED_SERVICE_ENDPOINT}${ASSISTED_SERVICE_V1_API_PATH}"
export ASSISTED_SERVICE_V2_API="${ASSISTED_SERVICE_ENDPOINT}${ASSISTED_SERVICE_V2_API_PATH}"

export CLUSTER_OVN="OVNKubernetes"

GENERATED_ASSETS="${SCRIPT_DIR}/.generated"
export CLUSTER_DIR="${GENERATED_ASSETS}/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}"

## Set Cluster ID
export CLUSTER_ID=""
if [ -f "${CLUSTER_DIR}/.cluster-id.nfo" ]; then
  export CLUSTER_ID=$(cat ${CLUSTER_DIR}/.cluster-id.nfo)
fi

## Check/load SSH Public Key
if [ -f "$SSH_PUB_KEY_PATH" ]; then
  export CLUSTER_SSH_PUB_KEY=$(cat ${SSH_PUB_KEY_PATH})
else
  echo "No SSH Public Key found!  Looking for ${SSH_PUB_KEY_PATH}"
  exit 1
fi
## Check/load Pull Secret
if [ -f "$PULL_SECRET_PATH" ]; then
  export PULL_SECRET=$(cat ${PULL_SECRET_PATH} | jq -R .)
else
  echo "No Pull Secret found!  Looking for ${PULL_SECRET_PATH}"
  exit 1
fi
## Check/load Offline Token
if [ -f "$RH_OFFLINE_TOKEN_PATH" ]; then
  export RH_OFFLINE_TOKEN=$(cat ${RH_OFFLINE_TOKEN_PATH})
else
  echo "No RH API Offline Token found!  Looking for ${RH_OFFLINE_TOKEN_PATH}"
  exit 1
fi
