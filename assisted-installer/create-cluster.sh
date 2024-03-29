#!/bin/bash

#set -e

generatePatchData() {

NODE_LENGTH=$(echo "${NODE_CFGS}" | jq -r '.nodes[].name' | wc -l)
if [ ${NODE_LENGTH} -eq 1 ]; then
  USER_MANAGED_NETWORKING=true
  PLATFORM_TYPE="none"
else
  USER_MANAGED_NETWORKING=false
  PLATFORM_TYPE="baremetal"
fi


cat << EOF
{
  "name": "${CLUSTER_NAME}",
  "openshift_version": "${CLUSTER_VERSION}",
  "cpu_architecture": "${CLUSTER_ARCH}",
  "base_dns_domain": "${CLUSTER_BASE_DNS}",
  "hyperthreading": "all",
  "ingress_vips": [{"ip": "${CLUSTER_INGRESS_VIP}"}],
  "api_vips":  [{"ip": "${CLUSTER_API_VIP}"}],
  "schedulable_masters": ${SCHEDULABLE_MASTERS},
  "high_availability_mode": "${HA_MODE}",
  "user_managed_networking": ${USER_MANAGED_NETWORKING},
  "platform": {
    "type": "${PLATFORM_TYPE}"
  },
  "cluster_network_cidr": "10.128.0.0/14",
  "cluster_network_host_prefix": 23,
  "service_network_cidr": "172.31.0.0/16",
  "network_type": "${CLUSTER_OVN}",
  "additional_ntp_source": "${NTP_SOURCE}",
  "vip_dhcp_allocation": false,
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

## Test DNS before creating the cluster
echo -e "\n===== Testing DNS for ${CLUSTER_NAME}.${CLUSTER_BASE_DNS}..."
if [ -z "$(dig +short api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS})" ]; then
  echo -e "  DNS for api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS} is not resolvable!\n"
  exit 1
fi

if [ -z "$(dig +short test.apps.${CLUSTER_NAME}.${CLUSTER_BASE_DNS})" ]; then
  echo -e "  DNS for test.apps.${CLUSTER_NAME}.${CLUSTER_BASE_DNS} is not resolvable!\n"
  exit 1
fi

## Save to file anyway for debugging purposes
echo "$(generatePatchData)" > ${CLUSTER_DIR}/cluster-config.json

echo "===== Creating a new cluster..."

CREATE_CLUSTER_REQUEST=$(curl -s --fail \
--header "Authorization: Bearer $ACTIVE_TOKEN" \
--header "Content-Type: application/json" \
--header "Accept: application/json" \
--request POST \
--data "$(generatePatchData)" \
"${ASSISTED_SERVICE_V2_API}/clusters")

if [ -z "$CREATE_CLUSTER_REQUEST" ]; then
  echo "===== Failed to create cluster!"
  curl -s -v  \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request POST \
    --data "$(generatePatchData)" \
    "${ASSISTED_SERVICE_V2_API}/clusters"
  exit 1
fi

CLUSTER_ID=$(printf '%s' "$CREATE_CLUSTER_REQUEST" | jq -r '.id')
echo "  CLUSTER_ID: ${CLUSTER_ID}"
echo $CLUSTER_ID > ${CLUSTER_DIR}/.cluster-id.nfo
