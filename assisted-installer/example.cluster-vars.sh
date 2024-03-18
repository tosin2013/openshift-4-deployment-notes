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
export NTP_SOURCE="0.rhel.pool.ntp.org"
#export DISCONNECTED_INSTALL=""  # Work in progress
#########################################################
## if you enable or disable dhcp both interfaces will use the samae options
## edit nmstate-generator.sh if you want one interface to have static and the other dhcp
export MULTI_NETWORK=false
#########################################################
## Enable or disable DHCP 
export USE_DHCP=false 
## Enable auto dns
export USE_AUTO_DNS=false
#########################################################
## Enable or disable VLAN
export USE_VLAN=false 
export VLAN_ID="10"

#########################################################
## Additional Node + Network Configuration
export CLUSTER_NODE_NET_DNS_SERVERS=("192.168.42.9" "192.168.42.10")

## Set Node Network Configuration
NODE1_CFG='{"name": "ocp01", "role": "control-plane", "mac_address": "52:54:00:00:00:01", "ipv4": {"address": "192.168.3.51", "gateway": "192.168.3.1", "prefix": "24", "iface": "enp1s0"}}'
NODE2_CFG='{"name": "ocp02", "role": "control-plane", "mac_address": "52:54:00:00:00:02", "ipv4": {"address": "192.168.3.52", "gateway": "192.168.3.1", "prefix": "24", "iface": "enp1s0"}}'
NODE3_CFG='{"name": "ocp03", "role": "control-plane", "mac_address": "52:54:00:00:00:03", "ipv4": {"address": "192.168.3.53", "gateway": "192.168.3.1", "prefix": "24", "iface": "enp1s0"}}'

NODE4_CFG='{"name": "ocp04", "role": "application-node", "mac_address": "52:54:00:00:00:04", "ipv4": {"address": "192.168.3.54", "gateway": "192.168.3.1", "prefix": "24", "iface": "enp1s0"}}'
NODE5_CFG='{"name": "ocp05", "role": "application-node", "mac_address": "52:54:00:00:00:05", "ipv4": {"address": "192.168.3.55", "gateway": "192.168.3.1", "prefix": "24", "iface": "enp1s0"}}'
#########################################################
## Remove _ front of variable below to add 3 workers on first install
###_NODE6_CFG='{"name": "ocp06", "role": "application-node", "mac_address": "52:54:00:00:00:06", "ipv4": {"address": "192.168.3.56", "gateway": "192.168.3.1", "prefix": "24", "iface": "enp1s0"}}'

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
export CLUSTER_VERSION="4.14"
## CLUSTER_RELEASE has been moved to query-supported-versions.sh
#export CLUSTER_RELEASE="4.9.6"

# CORE_USER_PWD - Leave blank to not set a core user password
export CORE_USER_PWD=""


if [ $DISCONNECTED_INSTALL == "true" ]; then
  export ASSISTED_SERVICE_HOSTNAME="192.168.1.10" # Change to your IP address
  export ASSISTED_SERVICE_PORT="8090" 
  export ASSISTED_SERVICE_PROTOCOL="http"
else 
  export ASSISTED_SERVICE_HOSTNAME="api.openshift.com"
  export ASSISTED_SERVICE_PORT="443" 
  export ASSISTED_SERVICE_PROTOCOL="https"
fi


#########################################################
## NOTHING TO SEE HERE - Don't edit past this point
export ASSISTED_SERVICE_ENDPOINT="${ASSISTED_SERVICE_PROTOCOL}://${ASSISTED_SERVICE_HOSTNAME}:${ASSISTED_SERVICE_PORT}"
export ASSISTED_SERVICE_V2_API_PATH="/api/assisted-install/v2"
export ASSISTED_SERVICE_V2_API="${ASSISTED_SERVICE_ENDPOINT}${ASSISTED_SERVICE_V2_API_PATH}"

export CLUSTER_OVN="OVNKubernetes"

GENERATED_ASSETS="${SCRIPT_DIR}/.generated"
export CLUSTER_DIR="${GENERATED_ASSETS}/${CLUSTER_NAME}.${CLUSTER_BASE_DNS}"

export HOSTS_MD5=$(echo -n "${NODE_CFGS}" | md5sum | awk '{print $1}')

## Set Cluster ID
export CLUSTER_ID=""
if [ -f "${CLUSTER_DIR}/.cluster-id.nfo" ]; then
  export CLUSTER_ID=$(cat ${CLUSTER_DIR}/.cluster-id.nfo)
fi

## Set InfraEnv ID
export INFRAENV_ID=""
if [ -f "${CLUSTER_DIR}/.infraenv-id.nfo" ]; then
  export INFRAENV_ID=$(cat ${CLUSTER_DIR}/.infraenv-id.nfo)
fi

## Set NEW_CLUSTER_ID
export NEW_CLUSTER_ID=""
if [ -f "${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo" ]; then
  export NEW_CLUSTER_ID=$(cat ${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo)
fi

## Set NEW_INFRAENV_ID
export NEW_INFRAENV_ID=""
if [ -f "${CLUSTER_DIR}/.new-infraenv-id-${HOSTS_MD5}.nfo" ]; then
  export NEW_INFRAENV_ID=$(cat ${CLUSTER_DIR}/.new-infraenv-id-${HOSTS_MD5}.nfo)
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
  export PULL_SECRET=$(jq -c '. |= tostring' ${PULL_SECRET_PATH})
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

## Set HA and Master Workload Scheduling
NODE_COUNT=$(echo $NODE_CFGS | jq -r '.nodes | length')
export HA_MODE="Full"
export SCHEDULABLE_MASTERS="false"

## SNO Setting Overrides
if [ "$NODE_COUNT" -eq "1" ]; then
  export HA_MODE="None"
  export CLUSTER_API_VIP=""
  export CLUSTER_INGRESS_VIP=""
fi

## Converged 3 Node Setting Overrides
if [ "$NODE_COUNT" -eq "3" ]; then
  export SCHEDULABLE_MASTERS="true"
fi
