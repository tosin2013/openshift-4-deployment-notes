#!/bin/bash

set -e

echo -e "\n===== Configuring Discovery ISO..."

if [ ! -z "$CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$CLUSTER_ID"
fi

if [ ! -z "$NEW_CLUSTER_ID" ]; then
  TARGET_CLUSTER_ID="$NEW_CLUSTER_ID"
fi

TEMP_ENSEMBLE=$(mktemp -p $CLUSTER_DIR)

NODE_COUNT=0
NODE_LENGTH=$(echo "${NODE_CFGS}" | jq -r '.nodes | length')
echo "  Working with ${NODE_LENGTH} nodes..."

## Loop through nodes, set up their variables
for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
  _jq() {
    echo ${node} | base64 --decode | jq -r ${1}
  }
  echo "  Generating ISO Config for $(_jq '.name')..."
  OPT_COM=""
  NODE_COUNT=$(expr $NODE_COUNT + 1)
  if [ $NODE_COUNT -ne $NODE_LENGTH ]; then
    OPT_COM=","
  fi
  
  NMSTATE_FILE=${CLUSTER_DIR}/$(_jq '.name').yaml
  NODE_INFO=$(mktemp -p $CLUSTER_DIR)
  # Encode the node's info
  ENCODED_JSON=$(jq -n --arg NET_YAML "$(cat $NMSTATE_FILE)" --arg OPT_COM "$OPT_COM" \
  '{
    "network_yaml": $NET_YAML,
    "mac_interface_map": [{"mac_address": "'$(_jq '.mac_address')'", "logical_nic_name": "'$(_jq '.ipv4.iface')'"}]
  }')
  echo "${ENCODED_JSON}${OPT_COM}" > $NODE_INFO
  cat $NODE_INFO >> $TEMP_ENSEMBLE
  ## Cleanup
  rm $NODE_INFO
done

generateStaticNetCfgJSON() {
cat << EOF
{
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "image_type": "${ISO_TYPE}",
  "pull_secret": ${PULL_SECRET},
  "static_network_config": [
    $(cat $TEMP_ENSEMBLE)
  ]
}
EOF
}
echo "$(generateStaticNetCfgJSON)" > ${CLUSTER_DIR}/add_host-${HOSTS_MD5}-iso_config.json
rm $TEMP_ENSEMBLE

echo -e "\n===== Patching Discovery ISO..."
ISO_CONFIGURATION_REQ=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID" \
-d @${CLUSTER_DIR}/add_host-${HOSTS_MD5}-iso_config.json \
--header "Content-Type: application/json" \
-H "Authorization: Bearer $ACTIVE_TOKEN")

if [ "$ISO_CONFIGURATION_REQ" -ne "201" ]; then
  echo "===== Failed to configure ISO!"
  exit 1
fi
