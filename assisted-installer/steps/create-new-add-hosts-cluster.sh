#!/bin/bash
set -e

echo -e "\n===== Creating Add Hosts cluster..."

generatePatchData() {
cat << EOF
{
  "name": "${CLUSTER_NAME}",
  "openshift_version": "${CLUSTER_VERSION}",
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

generateAddHostPatchData() {
cat << EOF
{
  "id": "${NEW_CLUSTER_ID}",
  "name": "${CLUSTER_NAME}",
  "openshift_version": "${CLUSTER_VERSION}",
  "api_vip_dnsname": "api.${CLUSTER_NAME}.${CLUSTER_BASE_DNS}",
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

generateAddHostBasicPatchData() {
cat << EOF
{
  "ssh_public_key": "$CLUSTER_SSH_PUB_KEY",
  "pull_secret": $PULL_SECRET
}
EOF
}

## check for the new cluster id
NEW_CLUSTER_ID=""

if [ -f "${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo" ]; then
  echo -e "  NEW_CLUSTER_ID found, using it..."
  NEW_CLUSTER_ID=$(cat "${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo")
fi

## Check to see if the cluster id is already set
if [ -z $NEW_CLUSTER_ID ]; then
  echo -e "  No NEW_CLUSTER_ID found, creating new cluster..."
  
  CREATE_ADD_HOST_CLUSTER_REQ=$(curl -s --fail \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
  --data "$(generatePatchData)" \
  "${ASSISTED_SERVICE_V2_API}/clusters")

  if [ -z "$CREATE_ADD_HOST_CLUSTER_REQ" ]; then
    echo "===== Failed to create AddHosts cluster!"
    exit 1
  fi

  #echo $CREATE_ADD_HOST_CLUSTER_REQ | python3 -m json.tool

  export NEW_CLUSTER_ID=$(printf '%s' "$CREATE_ADD_HOST_CLUSTER_REQ" | jq -r '.id')
  echo "  NEW_CLUSTER_ID: ${NEW_CLUSTER_ID}"
  echo $NEW_CLUSTER_ID > ${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo
  
  DELETE_ADD_HOST_CLUSTER_REQ=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request DELETE \
  "${ASSISTED_SERVICE_V2_API}/clusters/${NEW_CLUSTER_ID}")

  if [ "$DELETE_ADD_HOST_CLUSTER_REQ" -ne "204" ]; then
    echo "===== Failed to delete AddHosts cluster!"
    rm ${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo
    exit 1
  fi

  echo "  Setting new cluster as AddHost cluster..."
  
  echo $(generateAddHostPatchData) > ${CLUSTER_DIR}/.new-cluster-${HOSTS_MD5}-addHosts.json


#curl <HOST>:<PORT>/api/assisted-install/v2/infra-envs/<infra_env_id>/hosts  | jq '.'

  ADD_HOST_CLUSTER_REQ=$(curl -s --fail \
    --header "Authorization: Bearer $ACTIVE_TOKEN" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request POST \
    --data "$(generateAddHostPatchData)" \
    "${ASSISTED_SERVICE_V2_API}/clusters/$NEW_CLUSTER_ID/actions/install")

  if [ -z "$ADD_HOST_CLUSTER_REQ" ]; then
    echo $ADD_HOST_CLUSTER_REQ | python3 -m json.tool
    echo "===== Failed to create AddHosts cluster with spent UUID!"
    rm ${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo
    exit 1
  fi

  echo "  Setting basic configuration to AddHost cluster..."  
  
  BASIC_PATCH_ADD_HOST_CLUSTER_REQ=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "Authorization: Bearer $ACTIVE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request PATCH \
  --data "$(generateAddHostBasicPatchData)" \
  "${ASSISTED_SERVICE_V2_API}/clusters/${NEW_CLUSTER_ID}")

  if [ "$BASIC_PATCH_ADD_HOST_CLUSTER_REQ" -ne "201" ]; then
    echo "===== Failed to set basic AddHosts cluster config!"
    rm ${CLUSTER_DIR}/.new-cluster-id-${HOSTS_MD5}.nfo
    exit 1
  fi

else
  echo -e "  Using existing NEW_CLUSTER_ID: ${NEW_CLUSTER_ID}"
fi