#!/bin/bash

set -e
if [ -z $1 ];
then 
  WORKER_NAME=""
else 
  WORKER_NAME=$1
fi

echo -e "\n===== Configuring Discovery ISO..."
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
  if [ $MULTI_NETWORK  == false ];
  then 
    ENCODED_JSON=$(jq -n --arg NET_YAML "$(cat $NMSTATE_FILE)" --arg OPT_COM "$OPT_COM" \
    '{
      "network_yaml": $NET_YAML,
      "mac_interface_map": [{"mac_address": "'$(_jq '.mac_address')'", "logical_nic_name": "'$(_jq '.ipv4.iface')'"}]
    }')
  elif [ $MULTI_NETWORK  == true ];
  then 
    ENCODED_JSON=$(jq -n --arg NET_YAML "$(cat $NMSTATE_FILE)" --arg OPT_COM "$OPT_COM" \
    '{
      "network_yaml": $NET_YAML,  
      "mac_interface_map": [
        {
          "mac_address": "'$(_jq '.mac_address_int1')'",
          "logical_nic_name": "'$(_jq '.ipv4_int1.iface')'"
        },
        {
          "mac_address": "'$(_jq '.mac_address_int2')'",
          "logical_nic_name": "'$(_jq '.ipv4_int2.iface')'"
        }
    ]}')
  fi 
    echo "${ENCODED_JSON}${OPT_COM}" > $NODE_INFO
  cat $NODE_INFO >> $TEMP_ENSEMBLE
  ## Cleanup
  rm $NODE_INFO
done

generateStaticNetCfgJSON() {
#export PULL_SECRET=$(cat ${PULL_SECRET_PATH} | jq -R .)
cat << EOF
{
  "ssh_authorized_key": "$CLUSTER_SSH_PUB_KEY",
  "image_type": "${ISO_TYPE}",
  "pull_secret": ${PULL_SECRET},
  "static_network_config": [
    $(cat $TEMP_ENSEMBLE)
  ]
}
EOF
}


if [ -z ${WORKER_NAME} ];
then 
  echo "$(generateStaticNetCfgJSON)" > ${CLUSTER_DIR}/iso_config.json
  rm $TEMP_ENSEMBLE
  echo -e "\n===== Patching Discovery ISO..."
  ISO_CONFIGURATION_REQ=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "${ASSISTED_SERVICE_V2_API}/infra-envs/$INFRAENV_ID" \
  -d @${CLUSTER_DIR}/iso_config.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $ACTIVE_TOKEN")

  if [ "$ISO_CONFIGURATION_REQ" -ne "201" ]; then
    echo "===== Failed to configure ISO!"
    exit 1
  fi
else
  echo "$(generateStaticNetCfgJSON)" > ${CLUSTER_DIR}/iso_${WORKER_NAME}_config.json
  rm $TEMP_ENSEMBLE
  ISO_CONFIGURATION_REQ=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "${ASSISTED_SERVICE_V2_API}/infra-envs/${2}" \
      -d @${CLUSTER_DIR}/iso_${WORKER_NAME}_config.json \
      --header "Content-Type: application/json" \
      -H "Authorization: Bearer $ACTIVE_TOKEN")
  if [ "$ISO_CONFIGURATION_REQ" -ne "201" ]; then
    echo "===== Failed to configure ISO!"
    exit 1
  fi
  ####create and download new ISO ####
  CREATE_DISCOVERY_ISO=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "${ASSISTED_SERVICE_V1_API}/infra-envs/${2}" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -d @${CLUSTER_DIR}/iso_${WORKER_NAME}_config.json \
    --header "Content-Type: application/json")
  if [ "$CREATE_DISCOVERY_ISO" -ne "201" ]; then
    echo "===== Failed to create ISO!"
    exit 1
  fi
fi 
