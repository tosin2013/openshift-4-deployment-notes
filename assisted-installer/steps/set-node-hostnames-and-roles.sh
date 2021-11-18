#!/bin/bash

set -e

echo -e "\n===== Setting Node Hostnames and Roles..."

HOSTS=$(curl -s \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
    "${ASSISTED_SERVICE_V1_API}/clusters/${CLUSTER_ID}/hosts")

## Create temporary files
TEMP_HOST_ENSEMBLE=$(mktemp -p $CLUSTER_DIR)
TEMP_ROLE_ENSEMBLE=$(mktemp -p $CLUSTER_DIR)

## Compare with pulled hosts from the API
NODE_COUNT=0
NODE_LENGTH=$(echo "${HOSTS}" | jq -r '. | length')

## Loop through discovered hosts from the API
while read h; do
  ## See if we need a comma
  OPT_COM=""
  NODE_COUNT=$(expr $NODE_COUNT + 1)
  if [ $NODE_COUNT -ne $NODE_LENGTH ]; then
    OPT_COM=","
  fi

  ## Fix JSON...
  reshapenHost=${h%??}
  searchStr='"inventory":"{"'
  replaceStr='"inventory":{"'
  reshapenHost=$(echo $reshapenHost | sed "s|$searchStr|$replaceStr|")

  ## Get the host info
  HOST_ID=$(echo "${reshapenHost}}" | jq -r '.id')
  HOST_MAC_ADDRESS=$(echo "${reshapenHost}}" | jq -r '.inventory.interfaces[0].mac_address')

  ## Loop through defined nodes, match to this node if applicable
  for node in $(echo "${NODE_CFGS}" | jq -r '.nodes[] | @base64'); do
    _jq() {
      echo ${node} | base64 --decode | jq -r ${1}
    }

    ## See if this node MAC matches the discovered host
    #echo "  Checking for $(_jq '.mac_address') against ${HOST_MAC_ADDRESS}..."
    if [ "$(_jq '.mac_address')" == "$HOST_MAC_ADDRESS" ]; then
      #echo "  Matched node definition!  Setting up ${HOST_ID}..."
      NODE_HOST_JSON=$(mktemp -p $CLUSTER_DIR)
      NODE_ROLE_JSON=$(mktemp -p $CLUSTER_DIR)
      if [ "$(_jq '.role')" = "control-plane" ]; then
        SET_ROLE="master"
      fi
      if [ "$(_jq '.role')" = "application-node" ]; then
        SET_ROLE="worker"
      fi

      # Encode the node's info
      ENCODED_HOST_JSON=$(jq -n --arg HID "${HOST_ID}" --arg HN "$(_jq '.name')" \
      '{
        "id": $HID,
        "hostname": $HN
      }')
      ENCODED_ROLE_JSON=$(jq -n --arg HID "${HOST_ID}" --arg HROLE "${SET_ROLE}" \
      '{
        "id": $HID,
        "role": $HROLE
      }')

      echo "${ENCODED_HOST_JSON}${OPT_COM}" > $NODE_HOST_JSON
      cat $NODE_HOST_JSON >> $TEMP_HOST_ENSEMBLE

      echo "${ENCODED_ROLE_JSON}${OPT_COM}" > $NODE_ROLE_JSON
      cat $NODE_ROLE_JSON >> $TEMP_ROLE_ENSEMBLE

      rm $NODE_HOST_JSON
      rm $NODE_ROLE_JSON
      break;
    fi
  done  
done < <(printf '%s' "${HOSTS}" | jq -r -c '.[] | {id: .id, inventory: .inventory}')

generateHostPatchData() {
cat <<EOF
{
  "hosts_roles": [ $(cat $TEMP_ROLE_ENSEMBLE) ],
  "hosts_names": [ $(cat $TEMP_HOST_ENSEMBLE) ]
}
EOF
}

#echo $(generateHostPatchData)

# Set the Hostnames and Host Roles
echo "  Setting Host information..."
SET_HOST_INFO_REQ=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request PATCH \
  --data "$(generateHostPatchData)" \
  "${ASSISTED_SERVICE_V1_API}/clusters/${CLUSTER_ID}")

rm $TEMP_HOST_ENSEMBLE
rm $TEMP_ROLE_ENSEMBLE

if [ "$SET_HOST_INFO_REQ" -ne "201" ]; then
  echo "===== Failed to configure host names and roles!"
  exit 1
fi
