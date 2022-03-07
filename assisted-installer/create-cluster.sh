#!/bin/bash

#set -e

generatePatchData() {
cat << EOF
{
  "kind": "Cluster",
  "name": "${CLUSTER_NAME}",
  "openshift_version": "${CLUSTER_VERSION}",
  "ocp_release_image": "quay.io/openshift-release-dev/ocp-release:${CLUSTER_RELEASE}-x86_64",
  "base_dns_domain": "${CLUSTER_BASE_DNS}",
  "hyperthreading": "all",
  "ingress_vip": "${CLUSTER_INGRESS_VIP}",
  "api_vip": "${CLUSTER_API_VIP}",
  "schedulable_masters": ${SCHEDULABLE_MASTERS},
  "high_availability_mode": "${HA_MODE}",
  "user_managed_networking": false,
  "platform": {
    "type": "baremetal"
  },
  "cluster_networks": [
    {
      "cidr": "10.128.0.0/14",
      "host_prefix": 23
    }
  ],
  "service_networks": [
    {
      "cidr": "172.31.0.0/16"
    }
  ],
  "machine_networks": [
    {
      "cidr": "${CLUSTER_MACHINE_NETWORK}"
    }
  ],
  "network_type": "${CLUSTER_OVN}",
  "additional_ntp_source": "${NTP_SOURCE}",
  "vip_dhcp_allocation": false,
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

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
  exit 1
fi

CLUSTER_ID=$(printf '%s' "$CREATE_CLUSTER_REQUEST" | jq -r '.id')
echo "  CLUSTER_ID: ${CLUSTER_ID}"
echo $CLUSTER_ID > ${CLUSTER_DIR}/.cluster-id.nfo
