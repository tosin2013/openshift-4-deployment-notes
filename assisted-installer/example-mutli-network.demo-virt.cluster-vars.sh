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
export CLUSTER_NAME="ocp4"
export CLUSTER_BASE_DNS="example.com"
export CLUSTER_INGRESS_VIP="192.168.50.252"
export CLUSTER_API_VIP="192.168.50.253"
export CLUSTER_MACHINE_NETWORK="192.168.50.0/24"
export NTP_SOURCE="0.rhel.pool.ntp.org"
#########################################################
## if you enable or disable dhcp both interfaces will use the samae options
## cp example-mutli-network.cluster-vars.sh cluster-vars.sh
## edit nmstate-generator.sh if you want one interface to have static and the other dhcp
export MULTI_NETWORK=true
#########################################################
## Enable or disable DHCP 
export USE_DHCP=false 
## Enable auto dns
export USE_AUTO_DNS=false
#########################################################
## Enable or disable BOND
## Review Bonding types below
## https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/configuring-network-bonding_configuring-and-managing-networking#upstream-switch-configuration-depending-on-the-bonding-modes_configuring-network-bonding
export USE_BOND=true
#########################################################
## Enable or disable VLAN
export USE_VLAN=true
export VLAN_ID="1924"
export VLAN_ID_TWO="1925"

#########################################################
## Additional Node + Network Configuration
export CLUSTER_NODE_NET_DNS_SERVERS=("8.8.8.8" "1.1.1.1")

## Set Node Network Configuration
NODE1_CFG='{"name": "ocp01", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:01",  "ipv4_int1": {"address": "192.168.50.21", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:11", "ipv4_int2": {"address": "192.168.52.21", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
NODE2_CFG='{"name": "ocp02", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:02",  "ipv4_int1": {"address": "192.168.50.22", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:22", "ipv4_int2": {"address": "192.168.52.22", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
NODE3_CFG='{"name": "ocp03", "role": "control-plane", "mac_address_int1": "52:54:00:00:00:03",  "ipv4_int1": {"address": "192.168.50.23", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:33", "ipv4_int2": {"address": "192.168.52.23", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
## INFRA NODES
NODE4_CFG='{"name": "ocp04", "role": "application-node", "mac_address_int1": "52:54:00:00:00:04",  "ipv4_int1": {"address": "192.168.50.24", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:44", "ipv4_int2": {"address": "192.168.52.24", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
NODE5_CFG='{"name": "ocp05", "role": "application-node", "mac_address_int1": "52:54:00:00:00:05",  "ipv4_int1": {"address": "192.168.50.25", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:55", "ipv4_int2": {"address": "192.168.52.25", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
NODE6_CFG='{"name": "ocp06", "role": "application-node", "mac_address_int1": "52:54:00:00:00:06",  "ipv4_int1": {"address": "192.168.50.26", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:66", "ipv4_int2": {"address": "192.168.52.26", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
## Worker Nodes
NODE7_CFG='{"name": "ocp07", "role": "application-node", "mac_address_int1": "52:54:00:00:00:07",  "ipv4_int1": {"address": "192.168.50.27", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:77", "ipv4_int2": {"address": "192.168.52.27", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
NODE8_CFG='{"name": "ocp08", "role": "application-node", "mac_address_int1": "52:54:00:00:00:08",  "ipv4_int1": {"address": "192.168.50.28", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:88", "ipv4_int2": {"address": "192.168.52.28", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'
NODE9_CFG='{"name": "ocp09", "role": "application-node", "mac_address_int1": "52:54:00:00:00:09",  "ipv4_int1": {"address": "192.168.50.29", "gateway": "192.168.50.1", "prefix": "24", "iface": "enp1s0"}, "mac_address_int2": "52:54:00:00:00:99", "ipv4_int2": {"address": "192.168.52.29", "gateway": "192.168.52.1", "prefix": "24", "iface": "enp7s0"}}'

#########################################################
####INSERT NEW NODES UNDER HERE

## Add Nodes to the JSON array
export NODE_CFGS='{ "nodes": [ '${NODE1_CFG}', '${NODE2_CFG}', '${NODE3_CFG}', '${NODE4_CFG}', '${NODE5_CFG}', '${NODE6_CFG}', '${NODE7_CFG}', '${NODE8_CFG}', '${NODE9_CFG}' ] }'

### Deploy Controller and worker nodes
### Uncomment to deploy contoller nodes and workers
#export NODE_CFGS='{ "nodes": [ '${NODE1_CFG}', '${NODE2_CFG}', '${NODE3_CFG}', '${NODE4_CFG}', '${NODE5_CFG}', '${NODE6_CFG}' ] }'


#########################################################
### NEW CLUSTER ID for new clusters
###INSERT NEW CLUSTER ID HERE

#########################################################
## Optional Configuration
# ISO_TYPE can be 'minimal-iso' or 'full-iso'
export ISO_TYPE="full-iso"

## CLUSTER_VERSION just needs to be MAJOR.MINOR - actual release is queried from the API
export CLUSTER_VERSION="4.15"
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
