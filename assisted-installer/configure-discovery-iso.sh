#!/bin/bash

## Asssumes ./cluster-vars.sh has been source'd
## Bash execution modes are inherited from cluster-vars.sh
##set -xe

MAC1="52:54:00:00:00:01"
MAC2="52:54:00:00:00:02"
MAC3="52:54:00:00:00:03"

jq -n --arg $ISO_TYPE "$ISO_TYPE" --arg SSH_KEY "$CLUSTER_SSH_PUB_KEY" --arg NMSTATE_YAML1 "$(cat ocp01.yaml)" --arg NMSTATE_YAML2 "$(cat ocp02.yaml)" --arg NMSTATE_YAML3 "$(cat ocp03.yaml)" \
'{
  "ssh_public_key": $SSH_KEY,
  "image_type": "$ISO_TYPE",
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "'${MAC1}'", "logical_nic_name": "enp1s0"}]
    },
    {
      "network_yaml": $NMSTATE_YAML2,
      "mac_interface_map": [{"mac_address": "'${MAC2}'", "logical_nic_name": "enp1s0"}]
    },
    {
      "network_yaml": $NMSTATE_YAML3,
      "mac_interface_map": [{"mac_address": "'${MAC3}'", "logical_nic_name": "enp1s0"}]
    }
  ]
}' > ${CLUSTER_DIR}/iso_configuration.json

cat ${CLUSTER_DIR}/iso_configuration.json


curl -s -X POST "${ASSISTED_SERVICE_V1_API}/clusters/$CLUSTER_ID/downloads/image" \
  -d @${CLUSTER_DIR}/iso_configuration.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  | jq '.'